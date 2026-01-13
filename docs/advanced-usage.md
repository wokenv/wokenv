# Advanced Usage

Advanced configuration and usage scenarios for power users.

## Custom Docker Images

### Using Different Node Versions

Test with different Node.js versions by changing `wokenv.yml`:

```yaml
image:
  node: 22              # Use Node 22 instead of 20
  variant: alpine
  wpenv: 10
```

Or specify the full tag directly:

```yaml
image:
  tag: frugan/wokenv:node22-alpine-wpenv10
```

### Using Different Base Variants

**Alpine (default)** - Lightweight, fast:
```yaml
image:
  variant: alpine
```

**Bookworm (Debian 12)** - Stable, full-featured:
```yaml
image:
  variant: bookworm
```

**Trixie (Debian 13)** - Testing, latest packages:
```yaml
image:
  variant: trixie
```

### Override Image for Testing

Test a different image without changing `wokenv.yml`:

```bash
# In .env
WOKENV_IMAGE=frugan/wokenv:node22-bookworm-wpenv10
```

Or use `docker-compose.override.yml`:

```yaml
services:
  wokenv:
    image: frugan/wokenv:node22-bookworm-wpenv10
```

## Custom Services

### Adding Redis

Create `docker-compose.override.yml`:

```yaml
services:
  redis:
    image: redis:alpine
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    ports:
      - "6379:6379"
    networks:
      - wokenv
    restart: unless-stopped

networks:
  wokenv:
    external: true
    name: ${COMPOSE_PROJECT_NAME}-network
```

Install Redis plugin:

```bash
wokenv cli -- wp plugin install redis-cache --activate
wokenv cli -- wp redis enable
```

Configure in `wp-config.php` (via .wp-env.json):

```json
{
  "config": {
    "WP_REDIS_HOST": "redis",
    "WP_REDIS_PORT": 6379
  }
}
```

### Adding Elasticsearch

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: ${COMPOSE_PROJECT_NAME}-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    networks:
      - wokenv
    restart: unless-stopped

networks:
  wokenv:
    external: true
    name: ${COMPOSE_PROJECT_NAME}-network
```

Install ElasticPress plugin:

```bash
wokenv cli -- wp plugin install elasticpress --activate
```

### Adding Memcached

```yaml
services:
  memcached:
    image: memcached:alpine
    container_name: ${COMPOSE_PROJECT_NAME}-memcached
    ports:
      - "11211:11211"
    networks:
      - wokenv
    restart: unless-stopped

networks:
  wokenv:
    external: true
    name: ${COMPOSE_PROJECT_NAME}-network
```

Configure in `.wp-env.json`:

```json
{
  "config": {
    "WP_CACHE": true,
    "MEMCACHED_SERVERS": ["memcached:11211"]
  }
}
```

### Adding Custom Service

Generic template for any Docker service:

```yaml
services:
  my-service:
    image: my-image:latest
    container_name: ${COMPOSE_PROJECT_NAME}-my-service
    environment:
      - KEY=value
    ports:
      - "PORT:PORT"
    volumes:
      - ./data:/data
    networks:
      - wokenv
    restart: unless-stopped

networks:
  wokenv:
    external: true
    name: ${COMPOSE_PROJECT_NAME}-network
```

**Important:** Always include:
- `container_name: ${COMPOSE_PROJECT_NAME}-service-name`
- `networks: wokenv` (with external reference)
- Use `restart: unless-stopped` for persistence

## Multiple PHP Versions

### Testing Against Multiple Versions

Create a test script:

```bash
#!/bin/bash
# test-php-versions.sh

PHP_VERSIONS=("8.0" "8.1" "8.2" "8.3" "8.4")

for VERSION in "${PHP_VERSIONS[@]}"; do
    echo "Testing with PHP $VERSION..."
    
    # Update .wp-env.json
    echo "{\"phpVersion\": \"$VERSION\"}" > .wp-env.json
    
    # Restart environment
    wokenv destroy
    wokenv start
    
    # Run tests
    wokenv test
    
    # Store results
    echo "PHP $VERSION: $?" >> test-results.txt
done

echo "Testing complete. Results in test-results.txt"
```

Make executable and run:

```bash
chmod +x test-php-versions.sh
./test-php-versions.sh
```

### Matrix Testing with GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: PHP Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: ['8.0', '8.1', '8.2', '8.3', '8.4']
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
      
      - name: Install Wokenv
        run: |
          curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash
      
      - name: Configure PHP version
        run: |
          echo "{\"phpVersion\": \"${{ matrix.php }}\"}" > .wp-env.json
      
      - name: Start environment
        run: wokenv start
      
      - name: Run tests
        run: wokenv test
```

## Email Testing with Mailpit

### Basic Setup

Mailpit is included by default. Access at <http://localhost:8025>

### Configure WordPress

**Option 1: WP Mail SMTP Plugin**

```bash
# Install plugin
wokenv cli -- wp plugin install wp-mail-smtp --activate

# Configure via wp-config (recommended)
```

Add to `.wp-env.json`:

```json
{
  "config": {
    "WPMS_ON": true,
    "WPMS_SMTP_HOST": "mailpit",
    "WPMS_SMTP_PORT": 1025,
    "WPMS_SMTP_AUTH": false,
    "WPMS_MAILER": "smtp"
  }
}
```

**Option 2: Custom Plugin**

Create `wp-content/mu-plugins/mailpit-smtp.php`:

```php
<?php
/**
 * Plugin Name: Mailpit SMTP
 * Description: Configure WordPress to use Mailpit
 */

add_action('phpmailer_init', function($phpmailer) {
    $phpmailer->isSMTP();
    $phpmailer->Host = 'mailpit';
    $phpmailer->Port = 1025;
    $phpmailer->SMTPAuth = false;
});
```

**Option 3: Mailvat Plugin**

```bash
wokenv cli -- wp plugin install mailvat --activate
```

Then configure in WordPress admin: Settings → Mailvat → Set host to `mailpit:1025`

### Test Email Sending

```bash
# Send test email via WP-CLI
wokenv cli -- wp eval '
wp_mail(
    "test@example.com",
    "Test Email",
    "This is a test email from WordPress."
);
echo "Email sent!\n";
'
```

Check Mailpit UI at <http://localhost:8025>

### Mailpit API

Access Mailpit's API for automated testing:

```bash
# Get all messages
curl http://localhost:8025/api/v1/messages

# Get specific message
curl http://localhost:8025/api/v1/message/{ID}

# Delete all messages
curl -X DELETE http://localhost:8025/api/v1/messages
```

## Database Management

### Using phpMyAdmin

Access at <http://localhost:9000>

**Connection details:**
- Server: `{project-name}-mysql-1`
- Username: `root`
- Password: `password`
- Database: `wordpress`

### Using External Database Client

Find the dynamic MySQL port:

```bash
docker ps | grep mysql
```

Connect using:
- Host: `127.0.0.1`
- Port: (shown in docker ps output)
- User: `root`
- Password: `password`
- Database: `wordpress`

**Note:** The port changes on restart. Use phpMyAdmin for a stable connection.

### Database Operations

**Export database:**
```bash
wokenv cli -- wp db export backup.sql
```

**Import database:**
```bash
wokenv cli -- wp db import backup.sql
```

**Search and replace:**
```bash
wokenv cli -- wp search-replace 'oldurl.com' 'newurl.com' --dry-run
wokenv cli -- wp search-replace 'oldurl.com' 'newurl.com'
```

**Optimize database:**
```bash
wokenv cli -- wp db optimize
```

**Repair database:**
```bash
wokenv cli -- wp db repair
```

## Multiple Projects Simultaneously

### Configure Different Ports

**Project A:**

`.env`:
```bash
MAILPIT_WEB_PORT=8025
PHPMYADMIN_PORT=9000
```

`.wp-env.json`:
```json
{
  "port": 8888,
  "testsPort": 8889
}
```

**Project B:**

`.env`:
```bash
MAILPIT_WEB_PORT=8026
PHPMYADMIN_PORT=9001
```

`.wp-env.json`:
```json
{
  "port": 8890,
  "testsPort": 8891
}
```

Now both projects can run simultaneously:
- Project A: <http://localhost:8888>
- Project B: <http://localhost:8890>

## WordPress Multisite

### Enable Multisite

Add to `.wp-env.json`:

```json
{
  "config": {
    "WP_ALLOW_MULTISITE": true
  }
}
```

Restart:
```bash
wokenv restart
```

### Configure Multisite

Access WordPress admin and go to Tools → Network Setup.

Follow the instructions to add configuration to `wp-config.php` and `.htaccess`.

Since Wokenv uses Docker, you'll need to add config via `.wp-env.json`:

```json
{
  "config": {
    "WP_ALLOW_MULTISITE": true,
    "MULTISITE": true,
    "SUBDOMAIN_INSTALL": false,
    "DOMAIN_CURRENT_SITE": "localhost:8888",
    "PATH_CURRENT_SITE": "/",
    "SITE_ID_CURRENT_SITE": 1,
    "BLOG_ID_CURRENT_SITE": 1
  }
}
```

### Create Additional Sites

```bash
# Create new site
wokenv cli -- wp site create --slug=site2

# List all sites
wokenv cli -- wp site list

# Activate plugin on specific site
wokenv cli -- wp plugin activate my-plugin --url=localhost:8888/site2
```

## Performance Optimization

### Enable Object Cache

With Redis:

```bash
wokenv cli -- wp plugin install redis-cache --activate
wokenv cli -- wp redis enable
```

### Enable OPcache

OPcache is enabled by default in Wokenv images.

Verify:
```bash
wokenv cli -- wp eval 'phpinfo();' | grep opcache
```

### Database Query Optimization

Install Query Monitor:

```bash
wokenv cli -- wp plugin install query-monitor --activate
```

Access at <http://localhost:8888/wp-admin> and click "Query Monitor" in admin bar.

## Custom wp-config Settings

### via .wp-env.json

Add custom constants:

```json
{
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true,
    "WP_DEBUG_DISPLAY": false,
    "SCRIPT_DEBUG": true,
    "SAVEQUERIES": true,
    "WP_DISABLE_FATAL_ERROR_HANDLER": true,
    "CUSTOM_CONSTANT": "value"
  }
}
```

### via wp-config.php Override

Create `wp-content/mu-plugins/custom-config.php`:

```php
<?php
/**
 * Custom configuration
 */

// Your custom defines here
define('MY_CUSTOM_CONSTANT', 'value');
```

## Custom Make Targets

Create a `Makefile.local` file to add project-specific automation without modifying Wokenv core files.

### Creating Makefile.local

```bash
# Copy the example template
cp Makefile.local.dist Makefile.local

# Or create from scratch
cat > Makefile.local << 'EOF'
.PHONY: my-target

my-target:
 @echo "My custom target"
EOF
```

### Available Variables

Your `Makefile.local` has access to all Wokenv variables:

| Variable               | Description                  |
|------------------------|------------------------------|
| `DOCKER_COMPOSE`       | Full docker-compose command  |
| `WOKENV_IMAGE`         | Current Docker image         |
| `COMPOSE_PROJECT`      | Project name                 |
| `USER_ID` / `GROUP_ID` | Mapped IDs                   |
| `WOKENV_MAKEFILE`      | Path to centralized Makefile |

### Override Existing Targets

```makefile
# Makefile.local

# Override start with custom pre-checks
start:
 @echo "Running environment checks..."
 @docker info > /dev/null || (echo "Docker not running!"; exit 1)
 @echo "Starting WordPress..."
 @$(MAKE) -f $(WOKENV_MAKEFILE) start
 @echo "Post-start tasks..."
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp plugin activate my-plugin
```

### Call Centralized Targets

Use `$(WOKENV_MAKEFILE)` to call targets from the centralized Makefile:

```makefile
# Makefile.local

# Build assets before starting
start:
 @echo "Building assets..."
 @npm run build
 @$(MAKE) -f $(WOKENV_MAKEFILE) start

# Full reset and seed
reset-and-seed:
 @$(MAKE) -f $(WOKENV_MAKEFILE) destroy
 @$(MAKE) -f $(WOKENV_MAKEFILE) start
 @$(MAKE) seed-data
```

### Examples

**Database operations:**
```makefile
backup-db:
 @mkdir -p backups
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- \
  wp db export backups/backup-$(shell date +%Y%m%d-%H%M%S).sql
 @echo "✓ Backup created"

restore-latest:
 @LATEST=$$(ls -t backups/*.sql | head -1); \
 $(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db import $$LATEST
```

**Development workflow:**
```makefile
dev:
 @npm run watch &
 @$(MAKE) -f $(WOKENV_MAKEFILE) start

build-prod:
 @npm run build:prod
 @$(MAKE) -f $(WOKENV_MAKEFILE) composer-install -- --no-dev
 @echo "✓ Production build complete"
```

**Testing:**
```makefile
test-ci:
 @$(MAKE) -f $(WOKENV_MAKEFILE) test -- --coverage-text
 @$(MAKE) lint

lint:
 @$(DOCKER_COMPOSE) exec wokenv npm run env:composer -- run-script lint
```

### Team Workflow

Commit `Makefile.local.dist` with team-wide useful targets:

```makefile
# Makefile.local.dist

# Seed database with test data
seed:
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db reset --yes
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db import tests/fixtures/seed.sql
 @echo "✓ Test data loaded"

# Generate translations
i18n:
 @$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- \
  wp i18n make-pot . languages/my-plugin.pot
```

Team members copy to `Makefile.local` and customize as needed.
```

## Working with Git Submodules

### Add Plugin as Submodule

```bash
git submodule add https://github.com/vendor/plugin.git wp-content/plugins/plugin-name
```

### Add Theme as Submodule

```bash
git submodule add https://github.com/vendor/theme.git wp-content/themes/theme-name
```

### Clone Project with Submodules

```bash
git clone --recursive https://github.com/you/your-project.git
```

Or:

```bash
git clone https://github.com/you/your-project.git
cd your-project
git submodule update --init --recursive
```

## Custom Build Process

### Using npm Scripts

Add to `package.json`:

```json
{
  "scripts": {
    "build": "webpack --mode production",
    "watch": "webpack --mode development --watch",
    "build:css": "sass src/scss:assets/css",
    "build:js": "esbuild src/js/main.js --bundle --outfile=assets/js/main.js"
  }
}
```

Run inside container:

```bash
# One-time build
wokenv shell
npm run build
exit

# Or directly
wokenv cli -- npm run build
```

### Using Composer Scripts

Add to `composer.json`:

```json
{
  "scripts": {
    "lint": "@php vendor/bin/php-cs-fixer fix --dry-run",
    "lint:fix": "@php vendor/bin/php-cs-fixer fix",
    "test": "@php vendor/bin/phpunit",
    "test:coverage": "@php vendor/bin/phpunit --coverage-html coverage"
  }
}
```

Run:

```bash
wokenv composer-install run-script lint
wokenv composer-install run-script test
```

## Debugging

### Enable Xdebug

Not included by default. To add Xdebug, create a custom Dockerfile:

```dockerfile
FROM frugan/wokenv:latest

RUN apk add --no-cache php81-xdebug

COPY xdebug.ini /etc/php81/conf.d/50_xdebug.ini
```

`xdebug.ini`:
```ini
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
```

Build and use:

```bash
docker build -t wokenv:xdebug .
```

Update `wokenv.yml` or `.env`:
```bash
WOKENV_IMAGE=wokenv:xdebug
```

### Using Query Monitor

Install and activate:

```bash
wokenv cli -- wp plugin install query-monitor --activate
```

Access via admin bar: <http://localhost:8888/wp-admin>

### Using Debug Bar

```bash
wokenv cli -- wp plugin install debug-bar --activate
```

### View Error Logs

```bash
# Inside WordPress container
wokenv shell
tail -f /var/www/html/wp-content/debug.log

# Or directly
wokenv cli -- wp eval 'echo file_get_contents(WP_CONTENT_DIR . "/debug.log");'
```

## Next Steps

- Read [Troubleshooting](troubleshooting.md) for common issues
- Check [FAQ](faq.md) for frequently asked questions
- See [Architecture](architecture.md) for technical details
