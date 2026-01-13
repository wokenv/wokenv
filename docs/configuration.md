# Configuration

Complete guide to configuring Wokenv and your WordPress projects.

## Configuration Files

Wokenv uses several configuration files, each with a specific purpose:

### wokenv.yml (Versioned)

Project configuration safe to commit to version control.

```yaml
# Wokenv version for this project
version: "0.1.0"

# Project metadata
project:
  type: plugin  # plugin, theme, or core
  slug: my-plugin

# Docker image configuration
image:
  node: 20              # Node.js version: 18, 20, 22
  variant: alpine       # Base variant: alpine, bookworm, trixie
  wpenv: 10            # wp-env major version
  
  # Or specify full tag directly:
  # tag: frugan/wokenv:node20-alpine-wpenv10
```

**Available Docker image tags**: See [wokenv/base](https://github.com/wokenv/base) repository for all available tags.

**Node.js versions:**
- **18** - Maintenance LTS (until April 2025)
- **20** - Active LTS (recommended, until April 2026)
- **22** - Current (until April 2027)

**Base variants:**
- **alpine** - Lightweight, minimal footprint (recommended)
- **bookworm** - Debian 12, stable, full-featured
- **trixie** - Debian 13 testing, latest features

### .env (Local, Gitignored)

Runtime variables that vary per machine.

```bash
# Project name (used for container naming)
COMPOSE_PROJECT_NAME=my-plugin

# User/Group IDs (auto-detected, override only if needed)
USER_ID=1000
GROUP_ID=1000

# Optional: Override Docker image
# WOKENV_IMAGE=frugan/wokenv:node22-alpine-wpenv10

# Optional: Service ports
MAILPIT_WEB_PORT=8025
MAILPIT_SMTP_PORT=1025
PHPMYADMIN_PORT=9000
```

**Important:** Never commit `.env` to version control. Use `.env.dist` as a template instead.

### .env.dist (Versioned Template)

Template for `.env` that should be committed to version control. New developers copy this to `.env` and customize it.

### .wp-env.json (Versioned)

WordPress environment configuration for [@wordpress/env](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/).

**For plugins:**
```json
{
  "core": null,
  "phpVersion": "8.4",
  "plugins": ["."]
}
```

**For themes:**
```json
{
  "core": null,
  "phpVersion": "8.4",
  "themes": ["."]
}
```

**For core development:**
```json
{
  "core": "WordPress/WordPress#master",
  "phpVersion": "8.4"
}
```

**Common options:**
```json
{
  "core": "WordPress/WordPress#6.4",
  "phpVersion": "8.3",
  "plugins": [
    ".",
    "https://downloads.wordpress.org/plugin/woocommerce.latest-stable.zip"
  ],
  "themes": ["https://downloads.wordpress.org/theme/twentytwentyfour.zip"],
  "port": 8888,
  "testsPort": 8889,
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true,
    "SCRIPT_DEBUG": true
  },
  "mappings": {
    "wp-content/mu-plugins": "./mu-plugins"
  }
}
```

See [@wordpress/env documentation](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/) for all available options.

### docker-compose.override.yml (Optional, Local Only)

Add custom services or override defaults. This file is gitignored by default.

```yaml
version: '3.8'

services:
  # Add Redis cache
  redis:
    image: redis:alpine
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    ports:
      - "6379:6379"
    networks:
      - wokenv

  # Add Elasticsearch for search
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: ${COMPOSE_PROJECT_NAME}-elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    networks:
      - wokenv

networks:
  wokenv:
    external: true
    name: ${COMPOSE_PROJECT_NAME}-network
```

Services will automatically share the network with WordPress containers.

### Makefile.local (Optional, Local Only)

Add custom make targets without modifying the centralized Makefile.

**Purpose:** Project-specific automation and workflow customization.

**Example:**
```makefile
# Makefile.local
backup-db:
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db export backup-$(shell date +%Y%m%d).sql

deploy:
 @echo "Deploying..."
 @rsync -avz . user@server:/var/www/
```

**Override existing targets:**
```makefile
# Custom start with pre-checks
start:
 @echo "Running custom pre-start checks..."
 @$(MAKE) -f $(WOKENV_MAKEFILE) connect-network
 @$(MAKE) -f $(WOKENV_MAKEFILE) fix-perms
```

See `Makefile.local.example` for more examples.

**Why Gitignored:**
- Safe for local experimentation
- Personal workflow preferences
- Environment-specific automation
```

### package.json

NPM scripts for wp-env operations.

**For plugins/themes:**
```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "scripts": {
    "env:start": "wp-env start",
    "env:stop": "wp-env stop",
    "env:destroy": "wp-env destroy",
    "env:cli": "wp-env run cli",
    "env:composer": "wp-env run cli --env-cwd=wp-content/plugins/$(basename $(pwd)) composer",
    "env:test": "wp-env run tests-cli --env-cwd=wp-content/plugins/$(basename $(pwd)) vendor/bin/phpunit"
  }
}
```

These scripts are used by the Makefile and work without running `npm install` since wp-env is pre-installed globally in the Wokenv container.

### composer.json

PHP dependencies and development tools.

```json
{
  "name": "my-vendor/my-plugin",
  "require": {
    "php": "^8.0"
  },
  "require-dev": {
    "phpunit/phpunit": "^10.0",
    "wp-spaghetti/bedrock-autoloader-mu": "^1.0",
    "wp-spaghetti/wonolog": "^0.2"
  },
  "repositories": [
    {
      "type": "composer",
      "url": "https://wpackagist.org"
    }
  ]
}
```

## Configuration Precedence

When Wokenv starts, configuration is loaded in this order (later overrides earlier):

1. **Hardcoded defaults** in Makefile
2. **wokenv.yml** (project config)
3. **.env** (local runtime)
4. **docker-compose.yml** (base services from ~/.wokenv/)
5. **docker-compose.override.yml** (custom services)

Example:
```yaml
# wokenv.yml sets:
image:
  node: 20
  variant: alpine

# .env can override:
WOKENV_IMAGE=frugan/wokenv:node22-bookworm-wpenv10

# Result: .env wins, using node22-bookworm
```

## PHP Versions

Supported PHP versions (configured in `.wp-env.json`):

- `"phpVersion": "8.0"` - PHP 8.0
- `"phpVersion": "8.1"` - PHP 8.1
- `"phpVersion": "8.2"` - PHP 8.2
- `"phpVersion": "8.3"` - PHP 8.3
- `"phpVersion": "8.4"` - PHP 8.4 (default)

To test against multiple versions:

```bash
# Test with PHP 8.0
echo '{"phpVersion": "8.0"}' > .wp-env.json
wokenv destroy && wokenv start
wokenv test

# Test with PHP 8.4
echo '{"phpVersion": "8.4"}' > .wp-env.json
wokenv destroy && wokenv start
wokenv test
```

## Port Configuration

### WordPress Ports

Configured in `.wp-env.json`:

```json
{
  "port": 8888,      # Main site
  "testsPort": 8889  # Tests site
}
```

### Service Ports

Configured in `.env`:

```bash
MAILPIT_WEB_PORT=8025     # Mailpit web UI
MAILPIT_SMTP_PORT=1025    # SMTP server
PHPMYADMIN_PORT=9000      # phpMyAdmin
```

### Running Multiple Projects

To run multiple projects simultaneously, use different ports for each:

**Project A (.env):**
```bash
MAILPIT_WEB_PORT=8025
PHPMYADMIN_PORT=9000
```

**Project A (.wp-env.json):**
```json
{
  "port": 8888,
  "testsPort": 8889
}
```

**Project B (.env):**
```bash
MAILPIT_WEB_PORT=8026
PHPMYADMIN_PORT=9001
```

**Project B (.wp-env.json):**
```json
{
  "port": 8890,
  "testsPort": 8891
}
```

## Environment Variables

Available variables in `.env`:

| Variable               | Description         | Default                 |
|------------------------|---------------------|-------------------------|
| `USER_ID`              | Host user ID        | `$(id -u)`              |
| `GROUP_ID`             | Host group ID       | `$(id -g)`              |
| `COMPOSE_PROJECT_NAME` | Project identifier  | From `wokenv.yml`       |
| `WOKENV_IMAGE`         | Docker image to use | Built from `wokenv.yml` |
| `MAILPIT_WEB_PORT`     | Mailpit web UI port | `8025`                  |
| `MAILPIT_SMTP_PORT`    | Mailpit SMTP port   | `1025`                  |
| `PHPMYADMIN_PORT`      | phpMyAdmin port     | `9000`                  |

## Best Practices

### What to Commit

✅ **Always commit:**
- `wokenv.yml`
- `.env.dist`
- `.wp-env.json`
- `package.json`
- `composer.json`
- `wp-cli.yml`

❌ **Never commit:**
- `.env`
- `docker-compose.override.yml`
- `node_modules/`
- `vendor/`
- `.wp-env/`

✅ **Optionally commit:**
- `Makefile.local.dist` - Template for team customizations

### Recommended .gitignore

```gitignore
# Environment
.env
docker-compose.override.yml

# Dependencies
node_modules/
vendor/
composer.lock
package-lock.json

# WordPress
.wp-env/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db
```

### Team Collaboration

For team consistency:

1. **Commit wokenv.yml** with recommended settings
2. **Provide .env.dist** with good defaults
3. **Document any custom services** in README
4. **Pin PHP and WordPress versions** in .wp-env.json for reproducibility

### Security

- Never commit API keys or passwords to `.env`
- Use environment variables for secrets
- Keep `.env` in `.gitignore`
- Use different `COMPOSE_PROJECT_NAME` per project to avoid conflicts
