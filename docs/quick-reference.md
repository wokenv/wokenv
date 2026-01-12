# Quick Reference Guide

Essential commands and configurations for Wokenv.

## Installation

```bash
# Install Wokenv
curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash

# Manual installation
git clone https://github.com/wokenv/wokenv.git ~/.wokenv
```

## Project Setup

```bash
# In your plugin/theme directory
wokenv init         # Guided initialization (recommended)

# Or manually
ln -s ~/.wokenv/Makefile .
cp ~/.wokenv/.env.dist .env
cp ~/.wokenv/.wp-env.json .
cp ~/.wokenv/package.json .
cp ~/.wokenv/composer.json .
```

## Daily Commands

Use `wokenv <command>` or `make <command>` (if you have a local Makefile):

```bash
# Environment
wokenv install        # Install dependencies
wokenv start          # Start WordPress
wokenv stop           # Stop WordPress
wokenv restart        # Restart WordPress
wokenv destroy        # Delete everything

# Development
wokenv cli            # WP-CLI access
wokenv shell          # Bash shell
wokenv composer-install       # Install PHP deps
wokenv test           # Run tests

# Database
wokenv mysql          # MySQL CLI
wokenv reset-db       # Reset database

# Utilities
wokenv info           # Environment info
wokenv help           # Show all commands
wokenv fix-perms # Fix permissions
```

## Configuration Files

### `.env`
```bash
CUSTOM_IMAGE=frugan/wokenv:patched
USER_ID=$(id -u)
GROUP_ID=$(id -g)
```

### `.wp-env.json`
```json
{
  "core": null,
  "phpVersion": "8.4",
  "plugins": ["."]
}
```

### `composer.json` (recommended plugins)
```json
{
  "require-dev": {
    "wokenv/bedrock-autoloader-mu": "^1.0",
    "wokenv/wonolog": "^0.2"
  }
}
```

## WordPress Access

- **Site:** <http://localhost:8888>
- **Admin:** <http://localhost:8888/wp-admin>
- **Username:** admin
- **Password:** password
- **Tests:** <http://localhost:8889>

## WP-CLI Examples

```bash
# List plugins
make cli -- wp plugin list

# Install plugin
make cli -- wp plugin install query-monitor --activate

# Database operations
make cli -- wp db export
make cli -- wp db import backup.sql

# Search and replace
make cli -- wp search-replace 'oldurl.com' 'newurl.com'

# User management
make cli -- wp user list
make cli -- wp user create testuser test@example.com

# Content operations
make cli -- wp post list
make cli -- wp post create --post_title='Test' --post_status=publish
```

## Composer Examples

```bash
# Install dependencies
make composer

# Update dependencies
make composer-update

# Add a plugin
# Edit composer.json, then:
make composer
make restart
```

## Troubleshooting

```bash
# Permission issues
make fix-perms

# Port conflicts
# Edit .wp-env.json:
{ "port": 8890, "testsPort": 8891 }

# Complete reset
make destroy
make clean
rm -rf ~/.wp-env
make install
make start

# Check logs
docker logs $(docker ps -q --filter "name=wordpress")
```

## Docker Commands

```bash
# Pull specific image
docker pull frugan/wokenv:latest
docker pull frugan/wokenv:patched

# View running containers
docker ps

# Stop all WordPress containers
docker stop $(docker ps -q --filter "name=wordpress")

# Remove all WordPress containers
docker rm $(docker ps -aq --filter "name=wordpress")

# Clean up unused images
docker image prune -a
```

## PHP Versions

Supported versions in `.wp-env.json`:
- `"phpVersion": "8.0"`
- `"phpVersion": "8.1"`
- `"phpVersion": "8.2"`
- `"phpVersion": "8.3"`
- `"phpVersion": "8.4"`

## Common Workflows

### Creating a New Plugin
```bash
mkdir my-plugin && cd my-plugin
wokenv init         # Choose "Plugin" in wizard
wokenv install
wokenv start
```

### Creating a New Theme
```bash
mkdir my-theme && cd my-theme
wokenv init         # Choose "Theme" in wizard
wokenv install
wokenv start
```

### Testing Against Multiple PHP Versions
```bash
# PHP 8.0
echo '{"phpVersion": "8.0"}' > .wp-env.json
wokenv destroy && wokenv start
wokenv test

# PHP 8.4
echo '{"phpVersion": "8.4"}' > .wp-env.json
wokenv destroy && wokenv start
wokenv test
```

### Adding Development Plugins
```bash
# Edit composer.json
{
  "require-dev": {
    "wpackagist-plugin/query-monitor": "^3.16",
    "wpackagist-plugin/debug-bar": "^1.1"
  }
}

# Install and restart
wokenv composer-install
wokenv restart
```

## Environment Variables

Available in `.env`:

| Variable       | Description         | Default                |
|----------------|---------------------|------------------------|
| `USER_ID`      | Host user ID        | `$(id -u)`             |
| `GROUP_ID`     | Host group ID       | `$(id -g)`             |
| `CUSTOM_IMAGE` | Docker image to use | `frugan/wokenv:latest` |

## File Structure

```
your-plugin/
├── .env                 # Environment config
├── .wp-env.json        # wp-env config
├── package.json        # npm dependencies
├── composer.json       # PHP dependencies
├── Makefile            # Symlink to ~/.wokenv/Makefile
├── your-plugin.php     # Main plugin file
├── src/                # Source code
└── tests/              # PHPUnit tests
```

## Links

- **Repository:** <https://github.com/wokenv/wokenv>
- **Docker Hub:** <https://hub.docker.com/r/wokenv/wokenv>
- **Issues:** <https://github.com/wokenv/wokenv/issues>
- **wp-env Docs:** <https://github.com/WordPress/gutenberg/tree/trunk/packages/env>

## Getting Help

1. Check [FAQ.md](FAQ.md)
2. Review [README.md](README.md)
3. Search [existing issues](https://github.com/wokenv/wokenv/issues)
4. Open a [new issue](https://github.com/wokenv/wokenv/issues/new)

---

**Pro Tip:** Save this file locally for offline reference!
