[![Docker Pulls](https://img.shields.io/docker/pulls/frugan/wokenv)](https://hub.docker.com/r/frugan/wokenv)
[![GitHub Stars](https://img.shields.io/github/stars/wokenv/wokenv)](https://github.com/wokenv/wokenv/stargazers)
[![Build Status](https://github.com/wokenv/wokenv/actions/workflows/release.yml/badge.svg)](https://github.com/wokenv/wokenv/actions/workflows/release.yml)
[![GitHub Release](https://img.shields.io/github/v/release/wokenv/wokenv)](https://github.com/wokenv/wokenv/releases)
[![License](https://img.shields.io/github/license/wokenv/wokenv)](https://github.com/wokenv/wokenv/blob/main/LICENSE)

# Wokenv

> The perfect blend for WordPress development

Just like a **wok** expertly combines diverse ingredients into a harmonious dish, **Wokenv** blends **W**ordPress, D**o**c**k**er, and wp-**env** into one powerful development environment.

## Why "Wokenv"?

The name captures our philosophy:
- **wok** - The versatile cooking vessel that adapts to any recipe
- **env** - Your development environment

Together: A flexible, powerful workspace where you cook up great WordPress projects using the official [@wordpress/env](https://www.npmjs.com/package/@wordpress/env) package.

## Features

- **wp-env, without Node.js on your machine** - The official [@wordpress/env](https://www.npmjs.com/package/@wordpress/env) runs from a container: Docker is the only requirement
- **One file in your repository** - `wokenv.yml` is all you commit: no `package.json`, no `.env`, no `node_modules`
- **Standard configuration** - The `wp-env` section of `wokenv.yml` takes the same keys as `.wp-env.json`
- **Drop-in for existing projects** - Already have a `.wp-env.json`? Wokenv uses it as it is
- **Unpatched wp-env** - Wokenv never modifies wp-env, so every wp-env feature and update works as documented
- **Correct file ownership** - wp-env runs as your user, not as root: no more `sudo chown`
- **Mailpit built in** - Every email WordPress sends is caught and shown in a web UI
- **Everything in containers** - WP-CLI, Composer, PHPUnit, Xdebug, phpMyAdmin, `node` and `npm`
- **Plugins, themes and core** - The project type is detected and mounted for you
- **Centralized** - Wokenv lives in `~/.wokenv/`: update it once, every project benefits

## Requirements

- Docker with Compose v2 (Docker Desktop, or Docker Engine with the `docker compose` plugin)
- Git (only to install and update Wokenv)
- Linux, macOS or Windows with WSL 2

## Quick Start

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash
```

This clones Wokenv to `~/.wokenv`, links the `wokenv` command in `~/.local/bin` and pulls the Docker image.

### Setting Up a Project

```bash
cd /path/to/your-plugin-or-theme
wokenv init     # creates wokenv.yml
wokenv start    # starts WordPress
```

Then open:

- **WordPress**: <http://localhost:8888>
- **Admin**: <http://localhost:8888/wp-admin> (admin / password)
- **Mailpit (email)**: <http://localhost:8025>
- **phpMyAdmin (database)**: <http://localhost:9000>

### wokenv.yml

```yaml
# What this directory contains: plugin, theme, core or none.
type: plugin

# Catch every email WordPress sends: true, false or a custom port.
mailpit: true

# A standard wp-env configuration, the same keys as .wp-env.json.
wp-env:
  phpVersion: "8.3"
  phpmyadminPort: 9000
  testsEnvironment: false
  plugins:
    - https://downloads.wordpress.org/plugin/query-monitor.zip
```

See [Configuration](docs/configuration.md) for every option.

## Daily Workflow

```bash
wokenv start              # Start WordPress
wokenv start --xdebug     # Start with Xdebug enabled
wokenv stop               # Stop everything
wokenv wp plugin list     # WP-CLI
wokenv composer install   # Composer, in your project directory
wokenv npm run build      # Node.js tooling, without Node.js on the host
wokenv shell              # Bash in the WordPress CLI container
wokenv logs               # PHP and Docker logs
wokenv destroy            # Delete the environment (your files are safe)
wokenv help               # Show all commands
```

See the full command reference in the [Documentation](docs/README.md).

## How It Works

`wokenv` starts a small container with Node.js and wp-env, mounts your project and the Docker socket into it, and runs wp-env there as your own user. wp-env then creates the WordPress containers on your Docker daemon, exactly as it would if it were installed on your machine. See [Architecture](docs/architecture.md).

### Security note

The Wokenv container is given access to the Docker socket, which is equivalent to root access to the Docker host. This is what wp-env needs to manage containers, and the same access wp-env has when it runs directly on your machine. Do not run Wokenv with a `wokenv.yml` or `.wp-env.json` you do not trust: both can run arbitrary commands through wp-env lifecycle scripts.

### Docker User Namespace Remapping

⚠️ **Wokenv is NOT compatible with Docker `userns-remap` or rootless Docker.**

With these configurations the user inside the containers does not map to your user on the host, and you will experience permission issues. See [Troubleshooting](docs/troubleshooting.md).

## Contributing

For your contributions please use:

- [Conventional Commits](https://www.conventionalcommits.org)
- [Pull request workflow](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)

See [CONTRIBUTING](.github/CONTRIBUTING.md) for detailed guidelines.

## Sponsor

[<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" width="200" alt="Buy Me A Coffee">](https://buymeacoff.ee/frugan)

## License

(ɔ) Copyleft 2026 [Frugan](https://frugan.it).  
[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/), see [LICENSE](LICENSE) file.
