# Project Types

Complete guide for developing WordPress plugins, themes, and core with Wokenv.

## Plugin Development

### Quick Setup

```bash
mkdir my-plugin && cd my-plugin
wokenv init           # Choose "Plugin"
wokenv start          # Skip install if no npm/composer deps
```

### Project Structure

```
my-plugin/
├── wokenv.yml                      # Wokenv configuration (versioned)
├── .env.dist                       # Template (versioned)
├── .env                            # Local values (gitignored)
├── .wp-env.json                    # wp-env config (versioned)
├── package.json                    # npm scripts
├── composer.json                   # PHP dependencies
├── my-plugin.php                   # Main plugin file
├── src/                           # Plugin source code
│   ├── Plugin.php
│   ├── Admin/
│   ├── Frontend/
│   └── API/
├── assets/                        # Frontend assets
│   ├── css/
│   ├── js/
│   └── images/
├── languages/                     # Translation files
├── tests/                         # PHPUnit tests
│   ├── bootstrap.php
│   └── Unit/
├── phpunit.xml                    # PHPUnit configuration
├── .php-cs-fixer.dist.php        # Code style configuration
└── README.md
```

### Configuration

**wokenv.yml:**
```yaml
version: "0.1.0"
project:
  type: plugin
  slug: my-plugin
image:
  node: 20
  variant: alpine
  wpenv: 10
```

**.wp-env.json:**
```json
{
  "core": null,
  "phpVersion": "8.4",
  "plugins": ["."]
}
```

**composer.json:**
```json
{
  "name": "vendor/my-plugin",
  "type": "wordpress-plugin",
  "require": {
    "php": "^8.0"
  },
  "require-dev": {
    "phpunit/phpunit": "^10.0",
    "wp-spaghetti/bedrock-autoloader-mu": "^1.0",
    "wp-spaghetti/wonolog": "^0.2"
  }
}
```

### Development Workflow

```bash
# Start development
wokenv start

# Access your plugin
# WordPress: http://localhost:8888
# Admin: http://localhost:8888/wp-admin

# Activate plugin via WP-CLI
wokenv cli -- wp plugin activate my-plugin

# Or via admin panel
# Plugins → Installed Plugins → Activate
```

### Testing

```bash
# Install PHPUnit (if using composer)
wokenv install

# Run tests
wokenv test

# Run specific test class
wokenv test -- --filter=MyTestClass

# Run with coverage
wokenv test -- --coverage-html coverage/
```

### Adding Development Tools

**Query Monitor** (debugging):
```bash
wokenv cli -- wp plugin install query-monitor --activate
```

**Debug Bar**:
```bash
wokenv cli -- wp plugin install debug-bar --activate
```

Or add to `composer.json`:
```json
{
  "require-dev": {
    "wpackagist-plugin/query-monitor": "^3.16",
    "wpackagist-plugin/debug-bar": "^1.1"
  }
}
```

Then:
```bash
wokenv install
wokenv restart
```

### Plugin-Specific WP-CLI Commands

```bash
# Scaffold a new plugin
wokenv cli -- wp scaffold plugin my-new-plugin

# Check plugin status
wokenv cli -- wp plugin status my-plugin

# Update plugin
wokenv cli -- wp plugin update my-plugin

# Run plugin unit tests
wokenv cli -- wp plugin test my-plugin
```

## Theme Development

### Quick Setup

```bash
mkdir my-theme && cd my-theme
wokenv init           # Choose "Theme"
wokenv start          # Skip install if no npm/composer deps
```

### Project Structure

```
my-theme/
├── wokenv.yml                      # Wokenv configuration (versioned)
├── .env.dist                       # Template (versioned)
├── .env                            # Local values (gitignored)
├── .wp-env.json                    # wp-env config (versioned)
├── package.json                    # npm scripts
├── composer.json                   # PHP dependencies
├── style.css                       # Theme stylesheet (required)
├── functions.php                   # Theme functions
├── index.php                       # Main template
├── header.php                      # Header template
├── footer.php                      # Footer template
├── sidebar.php                     # Sidebar template
├── single.php                      # Single post template
├── page.php                        # Page template
├── archive.php                     # Archive template
├── search.php                      # Search results template
├── 404.php                         # 404 error template
├── template-parts/                # Reusable template parts
│   ├── content.php
│   ├── content-page.php
│   └── content-none.php
├── inc/                           # Theme includes
│   ├── customizer.php
│   ├── template-tags.php
│   └── template-functions.php
├── assets/                        # Frontend assets
│   ├── css/
│   ├── js/
│   └── images/
├── languages/                     # Translation files
├── tests/                         # PHPUnit tests
└── README.md
```

### Configuration

**wokenv.yml:**
```yaml
version: "0.1.0"
project:
  type: theme
  slug: my-theme
image:
  node: 20
  variant: alpine
  wpenv: 10
```

**.wp-env.json:**
```json
{
  "core": null,
  "phpVersion": "8.4",
  "themes": ["."]
}
```

**style.css (required):**
```css
/*
Theme Name: My WordPress Theme
Theme URI: https://example.com/my-theme
Author: Your Name
Author URI: https://example.com
Description: A WordPress theme starter template
Version: 1.0.0
Requires at least: 5.9
Tested up to: 6.9
Requires PHP: 8.0
License: GPL v3 or later
License URI: https://www.gnu.org/licenses/gpl-3.0.html
Text Domain: my-theme
Tags: custom-background, custom-logo, custom-menu, featured-images
*/
```

### Development Workflow

```bash
# Start development
wokenv start

# Access your theme
# WordPress: http://localhost:8888
# Admin: http://localhost:8888/wp-admin

# Activate theme via WP-CLI
wokenv cli -- wp theme activate my-theme

# Or via admin panel
# Appearance → Themes → Activate
```

### Theme-Specific WP-CLI Commands

```bash
# Check theme status
wokenv cli -- wp theme status my-theme

# Update theme
wokenv cli -- wp theme update my-theme

# List theme mods
wokenv cli -- wp theme mod list

# Enable theme mods
wokenv cli -- wp theme mod set background_color '#000000'
```

### Testing with Sample Content

```bash
# Import WordPress sample content
wokenv cli -- wp plugin install wordpress-importer --activate
wokenv cli -- wp import https://raw.githubusercontent.com/WPTT/theme-unit-test/master/themeunittestdata.wordpress.xml --authors=create

# Or manually via admin
# Tools → Import → WordPress → Run Importer
```

### Theme Check Plugin

```bash
# Install Theme Check plugin
wokenv cli -- wp plugin install theme-check --activate

# Or add to composer.json
{
  "require-dev": {
    "wpackagist-plugin/theme-check": "*"
  }
}
```

## WordPress Core Development

### Quick Setup

```bash
mkdir wordpress-core && cd wordpress-core
wokenv init           # Choose "WordPress Core"
wokenv start          # Skip install if no npm/composer deps
```

### Project Structure

```
wordpress-core/
├── wokenv.yml                      # Wokenv configuration (versioned)
├── .env.dist                       # Template (versioned)
├── .env                            # Local values (gitignored)
├── .wp-env.json                    # wp-env config (versioned)
├── package.json                    # npm scripts
└── README.md
```

### Configuration

**wokenv.yml:**
```yaml
version: "0.1.0"
project:
  type: core
  slug: wordpress-core
image:
  node: 20
  variant: alpine
  wpenv: 10
```

**.wp-env.json:**
```json
{
  "core": "WordPress/WordPress#master",
  "phpVersion": "8.4"
}
```

**Or use specific branch/tag:**
```json
{
  "core": "WordPress/WordPress#6.4",
  "phpVersion": "8.4"
}
```

### Development Workflow

```bash
# Start WordPress from specific branch
wokenv start

# Make changes to core files
# Files are in ~/.wp-env/{hash}-WordPress/

# Find WordPress path
wokenv cli -- wp eval 'echo ABSPATH;'

# Run WordPress tests
wokenv cli -- wp test
```

### Core Development Commands

```bash
# Check core files
wokenv cli -- wp core verify-checksums

# Update core
wokenv cli -- wp core update

# Download specific version
wokenv cli -- wp core download --version=6.4

# Check core version
wokenv cli -- wp core version
```

## Multi-Version Testing

### Test Against Different PHP Versions

```bash
# Edit .wp-env.json
{
  "phpVersion": "8.0"
}

# Restart
wokenv destroy
wokenv start
wokenv test

# Test next version
# Edit .wp-env.json to "8.4"
wokenv destroy
wokenv start
wokenv test
```

### Test Against Different WordPress Versions

```bash
# Edit .wp-env.json
{
  "core": "WordPress/WordPress#6.3"
}

wokenv destroy
wokenv start
wokenv test
```

## Recommended Packages

### For All Projects

**Query Monitor** - Debugging and performance analysis:
```bash
wokenv cli -- wp plugin install query-monitor --activate
```

**Debug Bar** - Development toolbar:
```bash
wokenv cli -- wp plugin install debug-bar --activate
```

### For Plugin/Theme Development

**Bedrock Autoloader** - Auto-load plugins from vendor/:
```json
{
  "require-dev": {
    "wp-spaghetti/bedrock-autoloader-mu": "^1.0"
  }
}
```

**Wonolog** - Advanced logging with PSR-3:
```json
{
  "require-dev": {
    "wp-spaghetti/wonolog": "^0.2"
  }
}
```

### For Testing

**PHPUnit**:
```json
{
  "require-dev": {
    "phpunit/phpunit": "^10.0"
  }
}
```

**PHP CodeSniffer**:
```json
{
  "require-dev": {
    "squizlabs/php_codesniffer": "^3.7",
    "wp-coding-standards/wpcs": "^3.0"
  }
}
```

## Best Practices

### Plugin Development

1. **Use proper namespace** - Avoid function name conflicts
2. **Follow WordPress Coding Standards** - Use WPCS
3. **Write unit tests** - Test your code
4. **Use wp-env for testing** - Test in clean environment
5. **Document your code** - Use PHPDoc
6. **Internationalization** - Make your plugin translatable

### Theme Development

1. **Follow Theme Review Guidelines** - If submitting to WordPress.org
2. **Use child themes** - For customizing existing themes
3. **Enqueue assets properly** - Use `wp_enqueue_script()` and `wp_enqueue_style()`
4. **Test with sample content** - Use Theme Unit Test data
5. **Make it accessible** - Follow WCAG guidelines
6. **Use WordPress hooks** - Don't modify core files

### Core Development

1. **Follow WordPress Core Standards** - Use WordPress coding style
2. **Write tests** - All core changes need tests
3. **Use proper commit messages** - Follow commit message guidelines
4. **Create patches** - Use SVN for WordPress core
5. **Test thoroughly** - Test across different PHP versions

## Common Tasks

### Add Custom Post Type (Plugin)

```php
// In your main plugin file
add_action('init', function() {
    register_post_type('my_cpt', [
        'public' => true,
        'label'  => 'My Custom Posts',
        'supports' => ['title', 'editor', 'thumbnail'],
    ]);
});
```

### Add Custom Widget (Theme)

```php
// In functions.php
class My_Custom_Widget extends WP_Widget {
    public function __construct() {
        parent::__construct('my_custom_widget', 'My Custom Widget');
    }
    
    // Widget methods here...
}

add_action('widgets_init', function() {
    register_widget('My_Custom_Widget');
});
```

### Add REST API Endpoint (Plugin)

```php
add_action('rest_api_init', function() {
    register_rest_route('myplugin/v1', '/data', [
        'methods' => 'GET',
        'callback' => 'my_api_callback',
        'permission_callback' => '__return_true',
    ]);
});
```

### Add Gutenberg Block (Plugin/Theme)

```bash
# Scaffold a block
wokenv cli -- wp scaffold block my-block --plugin=my-plugin
```

## Next Steps

- Read [Advanced Usage](advanced-usage.md) for custom services and configurations
- Check [Troubleshooting](troubleshooting.md) if you encounter issues
- See [FAQ](faq.md) for common questions
