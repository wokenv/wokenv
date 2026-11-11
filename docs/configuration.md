# Configuration

Wokenv is configured by a single file in the root of your project, `wokenv.yml`. It is the only file Wokenv needs in your repository, and it is safe to commit.

Create it with `wokenv init`, which detects whether the directory is a plugin, a theme or WordPress core.

## wokenv.yml

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/wokenv/wokenv/main/schemas/wokenv-schema.json

type: plugin
mailpit: true

wp-env:
  phpVersion: "8.3"
  phpmyadminPort: 9000
  testsEnvironment: false
```

The first line enables validation and completion in editors that support the YAML language server.

| Key       | Type                 | Default                | Description                                                              |
| --------- | -------------------- | ---------------------- | ------------------------------------------------------------------------ |
| `type`    | string               | detected               | `plugin`, `theme`, `core` or `none`: what the project directory contains |
| `mailpit` | boolean or integer   | `true`                 | Catch outgoing email; an integer sets the port of the web UI             |
| `image`   | string               | `frugan/wokenv:latest` | Wokenv image to run wp-env with                                          |
| `wp-env`  | mapping              | `{}`                   | A standard wp-env configuration                                          |

### type

Wokenv adds the project directory to the wp-env configuration according to its type:

| Type     | Effect                                                              |
| -------- | ------------------------------------------------------------------- |
| `plugin` | Mounted in `wp-content/plugins/` and activated                      |
| `theme`  | Mounted in `wp-content/themes/` (activate it with `wokenv wp theme activate`) |
| `core`   | Used as the WordPress installation                                  |
| `none`   | Nothing is added: list your sources in the `wp-env` section         |

Nothing is added when the `wp-env` section, or your `.wp-env.json`, already references the project directory (for example with `plugins: ["."]`).

### mailpit

When enabled, [Mailpit](https://mailpit.axllent.org/) receives every email sent with `wp_mail()`, and shows it at <http://localhost:8025>. Wokenv does this with a must-use plugin mounted at `wp-content/mu-plugins/wokenv-mailpit.php`.

If you map `wp-content` or `wp-content/mu-plugins` yourself, Wokenv cannot mount its plugin there: it prints a warning with the path of the file to copy into your own must-use plugins.

### image

The image must be a top-level, single-line value: it is the only key Wokenv reads before any container can run. You can also set it with the `WOKENV_IMAGE` environment variable. See [wokenv/base](https://github.com/wokenv/base) for the available tags.

### wp-env

Everything under `wp-env` is passed to wp-env. It accepts the same keys as `.wp-env.json`, documented in the [wp-env reference](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/#wp-env-json):

```yaml
wp-env:
  core: WordPress/WordPress#7.1
  phpVersion: "8.4"
  port: 8888
  plugins:
    - https://downloads.wordpress.org/plugin/query-monitor.zip
    - ../another-local-plugin
  themes:
    - WordPress/twentytwentyfive
  mappings:
    wp-content/uploads: ./tests/fixtures/uploads
  config:
    WP_DEBUG_DISPLAY: true
  multisite: false
  lifecycleScripts:
    afterStart: echo "WordPress is ready"
```

Relative paths are resolved from the directory of `wokenv.yml`. Local paths outside the project are supported.

Two things behave differently from a wp-env installed on the host:

- **Lifecycle scripts run in the Wokenv container.** They have `node`, `npm`, `git` and `docker`, but not the tools installed on your machine. To run something in WordPress, call wp-env from the script: `wp-env run cli wp ...`.
- **`autoPort` cannot see the ports of your machine**, because wp-env checks them from inside the container. Set the ports explicitly instead.

## Projects that already use wp-env

If your project has a `.wp-env.json`, Wokenv uses it. `wokenv.yml` can then be as small as:

```yaml
type: plugin
```

The `wp-env` section, when present, is applied on top of `.wp-env.json`, key by key. A `.wp-env.override.json` next to it keeps working as usual.

## Local overrides

For settings that should not be committed, use wp-env's own mechanisms:

- a `.wp-env.override.json` file in the project (add it to `.gitignore`)
- environment variables: `WP_ENV_PORT`, `WP_ENV_TESTS_PORT`, `WP_ENV_MYSQL_PORT`, `WP_ENV_PHPMYADMIN_PORT`, `WP_ENV_CORE`, `WP_ENV_PHP_VERSION`, `WP_ENV_MARIADB_VERSION` and the `WP_ENV_LIFECYCLE_SCRIPT_*` variables

```bash
WP_ENV_PORT=8080 wokenv start
```

## Environment variables

| Variable               | Default                 | Description                                         |
| ---------------------- | ----------------------- | --------------------------------------------------- |
| `WOKENV_IMAGE`         | from `wokenv.yml`       | Wokenv image to use                                 |
| `WOKENV_DOCKER_SOCKET` | `/var/run/docker.sock`  | Docker socket to mount in the Wokenv container      |
| `WOKENV_DATA_DIR`      | `~/.wokenv/var`         | Where Wokenv keeps wp-env's files for every project |
| `WOKENV_DIR`           | location of the command | Wokenv installation directory                       |
| `NO_COLOR`             |                         | Disable colored output                              |

## Running several projects at once

Every project gets its own containers, database and volumes. The ports are the only shared resource: give each project its own.

```yaml
mailpit: 8026

wp-env:
  port: 8890
  phpmyadminPort: 9001
```
