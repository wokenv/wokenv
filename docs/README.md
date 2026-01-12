# Wokenv Documentation

Complete documentation for Wokenv - WordPress Development Environment.

## Quick Links

- **[Main README](../README.md)** - Project overview and quick start
- **[Quick Reference](quick-reference.md)** - Command cheat sheet
- **[FAQ](faq.md)** - Frequently asked questions

## Getting Started

1. **[Installation](../README.md#installation)** - Install Wokenv
2. **[Quick Start](../README.md#quick-start)** - Set up your first project
3. **[Configuration](configuration.md)** - Configure your project
4. **[Commands](commands.md)** - Learn available commands

## Guides

### By Project Type

- **[Plugin Development](project-types.md#plugin-development)** - Build WordPress plugins
- **[Theme Development](project-types.md#theme-development)** - Create WordPress themes
- **[Core Development](project-types.md#wordpress-core-development)** - Contribute to WordPress core

### By Topic

- **[Configuration](configuration.md)** - All configuration options
  - wokenv.yml configuration
  - .env variables
  - .wp-env.json settings
  - docker-compose.override.yml
  - Port configuration
  - PHP versions

- **[Commands](commands.md)** - Complete command reference
  - Project commands (init, install, start, stop)
  - Development commands (cli, shell, composer)
  - Database commands (mysql, reset-db)
  - Utility commands (fix-perms, clean, info)
  - Wokenv management (self-update, self-check)

- **[Project Types](project-types.md)** - Development guides
  - Plugin development workflow
  - Theme development workflow
  - WordPress core development
  - Multi-version testing
  - Recommended packages

- **[Advanced Usage](advanced-usage.md)** - Power user features
  - Custom Docker images
  - Adding custom services (Redis, Elasticsearch, Memcached)
  - Multiple PHP versions
  - Email testing with Mailpit
  - Database management
  - Multiple projects simultaneously
  - WordPress Multisite
  - Performance optimization
  - Debugging

- **[Troubleshooting](troubleshooting.md)** - Fix common issues
  - Installation issues
  - Permission errors
  - Port conflicts
  - Environment won't start
  - Database problems
  - Network issues
  - Version mismatches
  - Docker issues

- **[Updating](updating.md)** - Keep everything current
  - Update Wokenv
  - Update Docker images
  - Update project dependencies
  - Update WordPress
  - Version compatibility
  - Rollback procedures

- **[Architecture](architecture.md)** - Technical details
  - System architecture
  - Configuration strategy
  - Docker-in-Docker design
  - Network connectivity
  - Permission handling
  - Version compatibility system

## Common Tasks

### Daily Workflow

```bash
wokenv start       # Start environment
wokenv cli         # Run WP-CLI commands
wokenv test        # Run tests
wokenv stop        # Stop environment
```

### Initial Setup

```bash
wokenv init        # Initialize project
wokenv install     # Install dependencies (optional)
wokenv start       # Start WordPress
```

### Development

```bash
# Install development plugin
wokenv cli -- wp plugin install query-monitor --activate

# Access database
wokenv mysql

# View logs
wokenv shell
tail -f /var/www/html/wp-content/debug.log
```

### Maintenance

```bash
# Update Wokenv
wokenv self-update

# Update project dependencies
wokenv composer-update
wokenv install-node

# Update WordPress
wokenv cli -- wp core update
wokenv cli -- wp plugin update --all
```

## Support

### Getting Help

1. **Search documentation** - Use the index above
2. **Check FAQ** - [faq.md](faq.md)
3. **Troubleshooting guide** - [troubleshooting.md](troubleshooting.md)
4. **GitHub issues** - <https://github.com/wokenv/wokenv/issues>

### Contributing

- **[Contributing Guide](../.github/CONTRIBUTING.md)** - How to contribute
- **[Code of Conduct](../.github/CODE_OF_CONDUCT.md)** - Community guidelines
- **[Issue Templates](../.github/ISSUE_TEMPLATE/)** - Report bugs or request features

## External Resources

- **[@wordpress/env Documentation](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/)** - Official wp-env docs

## Version

This documentation is for Wokenv v0.1.0.

For older versions, check the documentation in the corresponding Git tag:
- `git checkout v0.1.0 -- docs/`

## License

Documentation is part of Wokenv and is licensed under [GPL-3.0-or-later](../LICENSE).
