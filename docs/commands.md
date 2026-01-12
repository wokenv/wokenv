# Commands

Complete reference for all Wokenv commands.

## Command Syntax

Use either format:
```bash
wokenv <command>    # Via wokenv CLI (recommended)
make <command>      # Via Makefile (if you have a local symlink)
```

## Project Commands

### init

Initialize a new project with guided setup.

```bash
wokenv init
```

Creates:
- `wokenv.yml` - Project configuration
- `.env` and `.env.dist` - Environment variables
- `.wp-env.json` - WordPress environment config
- `package.json` - NPM scripts
- `composer.json` - PHP dependencies (for plugins/themes)
- `wp-cli.yml` - WP-CLI configuration
- Starter files based on project type

### install

Install npm and composer dependencies (optional).

```bash
wokenv install
```

**Note:** This command is optional. The `env:*` scripts work without it since wp-env is pre-installed. Only run this if your project uses npm packages or composer dependencies for building, testing, etc.

What it does:
- Runs `npm install` if `package.json` exists and `node_modules/` is missing
- Runs `composer install` if `composer.json` exists and `vendor/` is missing

### install-node

Install only npm dependencies.

```bash
wokenv install-node
```

Useful when you only need Node.js packages and want to skip Composer.

### start

Start WordPress environment and all services.

```bash
wokenv start
```

What happens:
1. Starts Docker Compose services (wokenv, mailpit, phpmyadmin)
2. Starts wp-env (WordPress, MySQL, Tests containers)
3. Connects wp-env containers to shared network
4. Fixes file permissions
5. Shows access URLs

**Access:**
- WordPress: <http://localhost:8888>
- Admin: <http://localhost:8888/wp-admin> (admin/password)
- Tests: <http://localhost:8889>
- Mailpit: <http://localhost:8025>
- phpMyAdmin: <http://localhost:9000>

### stop

Stop WordPress environment and all services.

```bash
wokenv stop
```

Gracefully stops:
- wp-env containers
- Docker Compose services

### restart

Restart WordPress environment.

```bash
wokenv restart
```

Equivalent to:
```bash
wokenv stop
wokenv start
```

### destroy

Destroy WordPress environment (deletes all data).

```bash
wokenv destroy
```

**⚠️ WARNING:** This permanently deletes:
- WordPress database
- All posts, pages, media
- Plugin and theme installations
- All WordPress files

You will be prompted for confirmation.

## Development Commands

### cli

Open WP-CLI in WordPress container.

```bash
wokenv cli [-- <wp-cli-command>]
```

**Examples:**
```bash
# Interactive shell
wokenv cli

# Run single command
wokenv cli -- wp plugin list

# Install and activate plugin
wokenv cli -- wp plugin install query-monitor --activate

# Export database
wokenv cli -- wp db export backup.sql

# Create post
wokenv cli -- wp post create --post_title='Hello' --post_status=publish

# Search and replace
wokenv cli -- wp search-replace 'oldurl.com' 'newurl.com'
```

See [WP-CLI documentation](https://developer.wordpress.org/cli/commands/) for all available commands.

### shell

Open bash shell in WordPress container.

```bash
wokenv shell
```

Provides direct shell access for debugging, file inspection, or running commands manually.

### composer-install

Install PHP dependencies via Composer.

```bash
wokenv composer-install
```

Runs inside WordPress container at the correct path. Equivalent to:
```bash
wokenv cli -- composer install
```

### composer-update

Update PHP dependencies via Composer.

```bash
wokenv composer-update
```

Equivalent to:
```bash
wokenv cli -- composer update
```

### test

Run PHPUnit tests.

```bash
wokenv test
```

Runs tests using the configuration in your project. Make sure you have:
- `phpunit.xml` or `phpunit.xml.dist`
- Tests in `tests/` directory
- PHPUnit installed via Composer

## Database Commands

### mysql

Access MySQL database CLI.

```bash
wokenv mysql
```

Opens MySQL client with:
- Database: `wordpress`
- User: `root`
- Password: `password`

**Examples:**
```sql
-- Show tables
SHOW TABLES;

-- Query posts
SELECT * FROM wp_posts LIMIT 10;

-- Check site URL
SELECT * FROM wp_options WHERE option_name IN ('siteurl', 'home');
```

### reset-db

Reset database (deletes all data).

```bash
wokenv reset-db
```

**⚠️ WARNING:** This permanently deletes all database content. You will be prompted for confirmation.

## Utility Commands

### fix-perms

Fix WordPress file permissions.

```bash
wokenv fix-perms
```

Sets correct ownership (1000:1000) on WordPress files. Useful if you encounter permission errors.

### clean

Remove node_modules and vendor directories.

```bash
wokenv clean
```

Deletes:
- `node_modules/`
- `package-lock.json`
- `vendor/`
- `composer.lock`

Useful for fresh dependency installation or freeing disk space.

### info

Show environment information.

```bash
wokenv info
```

Displays:
- Project configuration
- Docker image in use
- User/group mapping
- WordPress URLs
- Service URLs (Mailpit, phpMyAdmin)
- Database connection details
- Common commands

### connect-network

Connect wp-env containers to shared network.

```bash
wokenv connect-network
```

Manually connects WordPress containers to the Docker Compose network. Usually called automatically by `start`, but available if you need to re-connect manually.

### help

Show help message with all commands.

```bash
wokenv help
```

## Wokenv Management (self-* commands)

### self-update

Update Wokenv to latest version.

```bash
wokenv self-update
```

Updates:
- Wokenv CLI (`bin/wokenv`)
- Centralized Makefile
- Centralized docker-compose.yml
- Latest Docker images
- All supporting scripts

Shows changelog and prompts for confirmation.

### self-install-deps

Install optional dependencies (yq, PyYAML).

```bash
wokenv self-install-deps
```

Helps install:
- **yq** - Fast YAML processor (recommended)
- **PyYAML** - Python YAML library (alternative)

These improve YAML parsing reliability. Without them, Wokenv uses basic grep/sed parsing.

### self-check

Check Wokenv installation and dependencies.

```bash
wokenv self-check
```

Verifies:
- Wokenv directory exists
- Git repository status
- Command availability in PATH
- Docker and docker-compose installation
- Optional dependencies (yq, PyYAML)
- Current YAML parser being used

### self-info

Show Wokenv installation details.

```bash
wokenv self-info
```

Displays:
- Version information
- Install path
- Git version/branch/remote
- Available files and templates

## Other Commands

### version

Show Wokenv version.

```bash
wokenv version
# or
wokenv --version
wokenv -v
```

## Advanced Usage

### Passing Arguments to Scripts

Some commands accept additional arguments:

```bash
# Pass arguments to WP-CLI
wokenv cli -- wp plugin install woocommerce --activate

# Pass arguments to Composer
wokenv composer-install -- --no-dev

# Pass arguments to PHPUnit
wokenv test -- --filter=MyTestClass
```

### Chaining Commands

Use standard shell operators:

```bash
# Run sequentially
wokenv stop && wokenv start

# Run if previous succeeds
wokenv install && wokenv start

# Run regardless of previous result
wokenv destroy ; wokenv start
```

### Using with Makefile

If you have a local `Makefile` symlink (created during `wokenv init` wizard):

```bash
# All commands work the same
make start
make cli
make test

# Same as
wokenv start
wokenv cli
wokenv test
```

## Command Aliases

For convenience, you can create shell aliases:

```bash
# In ~/.bashrc or ~/.zshrc
alias we='wokenv'
alias wes='wokenv start'
alias wec='wokenv cli'

# Then use:
we start
wes
wec -- wp plugin list
```

## Exit Codes

Commands return standard exit codes:

- `0` - Success
- `1` - General error
- `2` - Misuse of command

Useful for scripting:

```bash
#!/bin/bash
if wokenv start; then
    echo "WordPress started successfully"
else
    echo "Failed to start WordPress"
    exit 1
fi
```

## Common Workflows

### Daily Development

```bash
# Morning
wokenv start

# Develop, test, repeat...
wokenv cli -- wp plugin list
wokenv test
wokenv shell

# Evening
wokenv stop
```

### Fresh Installation

```bash
wokenv destroy    # Clean slate
wokenv install    # Reinstall dependencies (if needed)
wokenv start      # Fresh WordPress
```

### Database Operations

```bash
# Backup
wokenv cli -- wp db export backup-$(date +%Y%m%d).sql

# Restore
wokenv cli -- wp db import backup-20260112.sql

# Reset
wokenv reset-db
```

### Testing Workflow

```bash
# Run tests
wokenv test

# Run specific test
wokenv test -- --filter=MyTest

# With coverage
wokenv test -- --coverage-html coverage/
```

## Tips

- Use `wokenv info` to quickly see all URLs and credentials
- Use `wokenv help` for a quick command reference
- Tab completion works with most shells (bash, zsh)
- Commands are designed to be idempotent - safe to run multiple times
