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

- **Uses Official WordPress Tools** - Built on [@wordpress/env](https://www.npmjs.com/package/@wordpress/env), the official WordPress development environment  
- **Works Out of the Box** - No Node.js installation needed on your host machine  
- **Docker-in-Docker Architecture** - Run WordPress containers inside a Docker container for complete isolation  
- **Handles Permissions Automatically** - No more `sudo chown` or permission headaches  
- **Smart Permission Management** - Automatically maps your host user to container user  
- **Includes Essential Services** - Mailpit for email testing, phpMyAdmin for database management  
- **Centralized Configuration** - One docker-compose.yml in `~/.wokenv/` powers all your projects  
- **Extensible via Makefile.local** - Add custom targets or override existing ones without modifying core files
- **Version Control Friendly** - Clear separation between committed config and local overrides  
- **Dynamic Network Connection** - Automatically connects wp-env containers to your custom services  
- **Updates Seamlessly** - Update Wokenv globally, all projects benefit immediately  
- **Version Compatibility** - Projects specify their Wokenv version, old projects keep working  
- **Zero Configuration Overhead** - Sensible defaults, optional customization only when needed  
- **Extends Easily** - Add Redis, Elasticsearch, or any service via docker-compose.override.yml  
- **Perfect for Plugin Development** - Isolated environments for each plugin project  
- **Perfect for Theme Development** - Test themes in clean WordPress installations  
- **WordPress Core Development** - Work on WordPress core with proper testing setup  
- **Multi-Version Testing** - Easily test across different PHP and WordPress versions  
- **Team Collaboration** - Consistent development environment across all team members  
- **Integration Testing** - Test your code with other services (Redis, Elasticsearch, etc.)  
- **Local Development** - Fast, reliable local WordPress development without hassle

## Requirements

- Docker (with Docker daemon running)
- Git
- Make (optional, can use `wokenv` command directly)

## Quick Start

### Installation

Install Wokenv with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash
```

This will:
- Clone Wokenv to `~/.wokenv`
- Install the `wokenv` command
- Pull the Docker image

### Setting Up a Project

1. **Navigate to your project directory:**
   ```bash
   cd /path/to/your-project
   ```

2. **Initialize with guided setup:**
   ```bash
   wokenv init
   ```

   The wizard will ask you:
   - What you're developing (plugin/theme/core)
   - Your project name
   - Creates all necessary configuration files

3. **Install dependencies (optional):**
   ```bash
   wokenv install    # Only if you use npm or composer dependencies
   ```

   **Note:** This step is optional. The `env:*` scripts in package.json work without this command since wp-env is pre-installed in the container. Only run `install` if your project uses npm packages or composer dependencies for building assets, testing, etc.

4. **Start WordPress:**
   ```bash
   wokenv start      # Start WordPress + services
   ```

5. **Access your environment:**
   - **WordPress**: <http://localhost:8888>
   - **Admin**: <http://localhost:8888/wp-admin> (admin/password)
   - **Mailpit (email)**: <http://localhost:8025>
   - **phpMyAdmin (database)**: <http://localhost:9000>

**Tip**: Create a `Makefile.local` file for project-specific custom targets. See `Makefile.local.dist` for examples.

## Daily Workflow

The most common commands you'll use:

```bash
wokenv start          # Start WordPress + all services
wokenv stop           # Stop everything
wokenv restart        # Restart everything
wokenv cli            # Open WP-CLI
wokenv shell          # Open bash shell
wokenv info           # Show environment information
wokenv help           # Show all commands
```

See full command reference in [Documentation](docs/README.md).

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
