# Example: Basic Plugin Project

This example shows a typical plugin project structure using Wokenv.

## Project Structure

```
my-plugin/
├── .env                 # Your environment variables
├── .wp-env.json        # Your wp-env configuration
├── package.json        # Your npm dependencies
├── composer.json       # Your PHP dependencies
├── Makefile            # Symlink to ~/.wokenv/Makefile
├── my-plugin.php       # Main plugin file
├── src/                # Plugin source code
│   └── Plugin.php
├── tests/              # PHPUnit tests
│   └── PluginTest.php
└── README.md
```

## Quick Setup

1. **Create your plugin directory:**
   ```bash
   mkdir -p ~/projects/my-plugin
   cd ~/projects/my-plugin
   ```

2. **Initialize with Wokenv:**
   ```bash
   wokenv init
   ```

   In the wizard:
   - Choose: **1) Plugin**
   - Enter slug: **my-plugin** (or press Enter for default)
   - Choose Makefile option (recommended: 1)
   - Accept default files to copy

3. **Install dependencies and start:**
   ```bash
   wokenv install
   wokenv start
   ```

4. **Access WordPress:**
   - Site: <http://localhost:8888>
   - Admin: <http://localhost:8888/wp-admin>
   - User: admin / password

## Development Workflow

### Add a new feature
```bash
# Edit your PHP files
vim src/Plugin.php

# Run tests
wokenv test

# Access WP-CLI
wokenv cli

# Restart if needed
wokenv restart
```

### Add development plugins
Edit `composer.json`:
```json
{
  "require-dev": {
    "wpackagist-plugin/query-monitor": "^3.16",
    "wpackagist-plugin/debug-bar": "^1.1"
  }
}
```

Then run:
```bash
wokenv composer-install
wokenv restart
```

## Tips

- Use `wokenv info` to see all WordPress URLs and credentials
- Use `wokenv help` to see all available commands
- Add `.env` to `.gitignore` (already done in template)
- Commit `composer.lock` and `package-lock.json` for reproducibility
