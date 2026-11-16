#!/usr/bin/env node
'use strict';

/**
 * Translates a project's wokenv.yml into the files Wokenv needs at runtime.
 *
 * Runs inside the Wokenv container (never on the host), so the only host
 * requirement stays Docker. Everything is written to the project's state
 * directory, outside the project itself:
 *
 *   .wp-env.json           the wp-env configuration, with absolute local paths
 *   .wp-env.override.json  copy of the project's override file, if any
 *   project.env            KEY=value facts the host CLI needs
 *   compose.override.json  extra mounts and Mailpit ports for docker compose
 */

const fs = require( 'fs' );
const path = require( 'path' );
const yaml = require( 'js-yaml' );

const KNOWN_KEYS = [ 'image', 'type', 'mailpit', 'wp-env' ];
const PROJECT_TYPES = [ 'plugin', 'theme', 'core', 'none' ];
const DEFAULT_MAILPIT_PORT = 8025;

function fail( message ) {
  process.stderr.write( `wokenv: ${ message }\n` );
  process.exit( 1 );
}

function warn( message ) {
  process.stderr.write( `wokenv: warning: ${ message }\n` );
}

function parseArgs( argv ) {
  const args = {};
  for ( let i = 0; i < argv.length; i += 2 ) {
    if ( ! argv[ i ].startsWith( '--' ) || argv[ i + 1 ] === undefined ) {
      fail( `invalid argument: ${ argv[ i ] }` );
    }
    args[ argv[ i ].slice( 2 ) ] = argv[ i + 1 ];
  }
  for ( const name of [ 'project', 'state', 'lib', 'home' ] ) {
    if ( ! args[ name ] ) {
      fail( `missing --${ name }` );
    }
  }
  return args;
}

function isPlainObject( value ) {
  return value !== null && typeof value === 'object' && ! Array.isArray( value );
}

function readJson( file ) {
  try {
    return JSON.parse( fs.readFileSync( file, 'utf8' ) );
  } catch ( error ) {
    fail( `${ file }: ${ error.message }` );
  }
}

/**
 * Mirrors how wp-env recognizes a local source: a path that starts with ".",
 * "~" or "/". Anything else is a GitHub repository, a URL or a zip.
 *
 * @param {*} source A wp-env source string.
 * @return {boolean} Whether the source points to the local filesystem.
 */
function isLocalSource( source ) {
  return typeof source === 'string' && /^(\.|~|\/)/.test( source );
}

function createPathResolver( projectDir, homeDir ) {
  return ( source ) => {
    if ( ! isLocalSource( source ) ) {
      return source;
    }
    if ( source === '~' || source.startsWith( '~/' ) ) {
      return path.join( homeDir, source.slice( 1 ) );
    }
    return path.resolve( projectDir, source );
  };
}

/**
 * Rewrites every local source to an absolute host path, because the generated
 * file lives outside the project and wp-env resolves relative paths against
 * the directory of the config file.
 *
 * @param {Object}   config  A wp-env config (root or environment level).
 * @param {Function} resolve Path resolver.
 */
function absolutizeSources( config, resolve ) {
  if ( typeof config.core === 'string' ) {
    config.core = resolve( config.core );
  }
  for ( const key of [ 'plugins', 'themes' ] ) {
    if ( Array.isArray( config[ key ] ) ) {
      config[ key ] = config[ key ].map( resolve );
    }
  }
  if ( isPlainObject( config.mappings ) ) {
    for ( const target of Object.keys( config.mappings ) ) {
      config.mappings[ target ] = resolve( config.mappings[ target ] );
    }
  }
  if ( isPlainObject( config.env ) ) {
    for ( const environment of Object.values( config.env ) ) {
      if ( isPlainObject( environment ) ) {
        absolutizeSources( environment, resolve );
      }
    }
  }
}

function collectLocalSources( config, found = new Set() ) {
  const add = ( source ) => {
    if ( isLocalSource( source ) ) {
      found.add( source );
    }
  };
  add( config.core );
  ( Array.isArray( config.plugins ) ? config.plugins : [] ).forEach( add );
  ( Array.isArray( config.themes ) ? config.themes : [] ).forEach( add );
  Object.values( isPlainObject( config.mappings ) ? config.mappings : {} ).forEach( add );
  if ( isPlainObject( config.env ) ) {
    for ( const environment of Object.values( config.env ) ) {
      if ( isPlainObject( environment ) ) {
        collectLocalSources( environment, found );
      }
    }
  }
  return found;
}

function fileHasHeader( file, header ) {
  try {
    // Headers live in the first 8 KiB, the same window WordPress reads.
    const buffer = Buffer.alloc( 8192 );
    const fd = fs.openSync( file, 'r' );
    const length = fs.readSync( fd, buffer, 0, buffer.length, 0 );
    fs.closeSync( fd );
    return new RegExp( `^[ \\t/*#@]*${ header }:`, 'im' ).test(
      buffer.toString( 'utf8', 0, length )
    );
  } catch {
    return false;
  }
}

function detectProjectType( projectDir ) {
  if ( fs.existsSync( path.join( projectDir, 'wp-settings.php' ) ) ) {
    return 'core';
  }
  if ( fileHasHeader( path.join( projectDir, 'style.css' ), 'Theme Name' ) ) {
    return 'theme';
  }
  const hasPluginFile = fs
    .readdirSync( projectDir )
    .filter( ( file ) => file.endsWith( '.php' ) )
    .some( ( file ) => fileHasHeader( path.join( projectDir, file ), 'Plugin Name' ) );
  return hasPluginFile ? 'plugin' : 'none';
}

function isInside( parent, child ) {
  const relative = path.relative( parent, child );
  return relative === '' || ( ! relative.startsWith( '..' ) && ! path.isAbsolute( relative ) );
}

function parseMailpit( value ) {
  if ( value === undefined || value === true ) {
    return DEFAULT_MAILPIT_PORT;
  }
  if ( value === false ) {
    return 0;
  }
  if ( Number.isInteger( value ) && value > 0 && value < 65536 ) {
    return value;
  }
  fail( '"mailpit" must be true, false or a port number' );
}

function main() {
  const args = parseArgs( process.argv.slice( 2 ) );
  const projectDir = path.resolve( args.project );
  const stateDir = path.resolve( args.state );
  const resolve = createPathResolver( projectDir, args.home );

  // 1. Read wokenv.yml.
  let wokenv;
  try {
    wokenv = yaml.load( fs.readFileSync( path.join( projectDir, 'wokenv.yml' ), 'utf8' ) ) ?? {};
  } catch ( error ) {
    fail( `wokenv.yml: ${ error.message }` );
  }
  if ( ! isPlainObject( wokenv ) ) {
    fail( 'wokenv.yml must contain a mapping' );
  }
  for ( const key of Object.keys( wokenv ) ) {
    if ( ! KNOWN_KEYS.includes( key ) ) {
      warn( `unknown key "${ key }" in wokenv.yml` );
    }
  }
  if ( wokenv.type !== undefined && ! PROJECT_TYPES.includes( wokenv.type ) ) {
    fail( `"type" must be one of: ${ PROJECT_TYPES.join( ', ' ) }` );
  }
  if ( wokenv[ 'wp-env' ] !== undefined && ! isPlainObject( wokenv[ 'wp-env' ] ) ) {
    fail( '"wp-env" must be a mapping' );
  }
  const mailpitPort = parseMailpit( wokenv.mailpit );

  // 2. Build the wp-env config: the project's .wp-env.json, if any, is the
  //    base and the "wp-env" section of wokenv.yml is applied on top of it.
  const nativeConfigPath = path.join( projectDir, '.wp-env.json' );
  const config = {
    ...( fs.existsSync( nativeConfigPath ) ? readJson( nativeConfigPath ) : {} ),
    ...( wokenv[ 'wp-env' ] ?? {} ),
  };
  absolutizeSources( config, resolve );

  // 3. Add the project itself, unless the config already references it.
  const type = wokenv.type ?? detectProjectType( projectDir );
  const referencesProject = [ ...collectLocalSources( config ) ].some(
    ( source ) => path.resolve( source ) === projectDir
  );
  if ( ! referencesProject ) {
    if ( type === 'plugin' ) {
      config.plugins = [ projectDir, ...( config.plugins ?? [] ) ];
    } else if ( type === 'theme' ) {
      config.themes = [ projectDir, ...( config.themes ?? [] ) ];
    } else if ( type === 'core' ) {
      config.core = projectDir;
    }
  }

  // 4. Route WordPress mail to Mailpit through a plugin. It is a regular
  //    plugin, not a mapped must-use file: Docker creates missing mount points
  //    as root, and a root-owned file in a root-owned mu-plugins directory
  //    cannot be removed by wp-env destroy. wp-env mounts plugins as
  //    directories, whose empty mount points the user can remove.
  if ( mailpitPort ) {
    config.plugins = [
      ...( config.plugins ?? [] ),
      path.join( args.lib, 'plugins', 'wokenv-mailpit' ),
    ];
  }

  // 5. The override file follows the same rules as the main one.
  const overrideSource = path.join( projectDir, '.wp-env.override.json' );
  const overrideTarget = path.join( stateDir, '.wp-env.override.json' );
  if ( fs.existsSync( overrideSource ) ) {
    const override = readJson( overrideSource );
    absolutizeSources( override, resolve );
    fs.writeFileSync( overrideTarget, JSON.stringify( override, null, 2 ) + '\n' );
  } else {
    fs.rmSync( overrideTarget, { force: true } );
  }

  // 6. Local sources outside the project must be visible to wp-env too.
  const sources = collectLocalSources( config );
  if ( fs.existsSync( overrideTarget ) ) {
    collectLocalSources( readJson( overrideTarget ), sources );
  }
  const extraMounts = [ ...sources ]
    .map( ( source ) => path.resolve( source ) )
    .filter( ( source ) => ! isInside( projectDir, source ) && ! isInside( args.lib, source ) )
    .filter( ( source, index, all ) => all.indexOf( source ) === index );
  const services = {};
  if ( extraMounts.length ) {
    services.wokenv = { volumes: extraMounts.map( ( source ) => `${ source }:${ source }` ) };
  }
  if ( mailpitPort ) {
    services.mailpit = { ports: [ `127.0.0.1:${ mailpitPort }:8025` ] };
  }

  // 7. Where commands such as composer run inside the WordPress containers.
  const basename = path.basename( projectDir );
  const envCwd = {
    plugin: `wp-content/plugins/${ basename }`,
    theme: `wp-content/themes/${ basename }`,
  }[ type ] ?? '.';

  fs.writeFileSync(
    path.join( stateDir, '.wp-env.json' ),
    JSON.stringify( config, null, 2 ) + '\n'
  );
  fs.writeFileSync(
    path.join( stateDir, 'compose.override.json' ),
    JSON.stringify( { services }, null, 2 ) + '\n'
  );
  fs.writeFileSync(
    path.join( stateDir, 'project.env' ),
    [
      `TYPE=${ type }`,
      `ENV_CWD=${ envCwd }`,
      `MAILPIT_PORT=${ mailpitPort }`,
      '',
    ].join( '\n' )
  );
}

main();
