# Updating

How to keep Wokenv and your projects up to date.

## Update Wokenv

### Automatic Update

The easiest way to update:

```bash
wokenv self-update
```

This updates:
- Wokenv CLI (`bin/wokenv`)
- Centralized Makefile
- Centralized docker-compose.yml
- Template files
- Documentation
- Latest Docker images

**What happens:**
1. Fetches latest changes from GitHub
2. Shows changes to be applied
3. Prompts for confirmation
4. Pulls latest changes
5. Updates Docker images
6. Shows changelog

### Manual Update

If `self-update` doesn't work:

```bash
cd ~/.wokenv
git fetch origin main
git pull origin main
chmod +x bin/wokenv
```

### Update to Specific Version

```bash
cd ~/.wokenv
git fetch --tags
git checkout v0.2.0
```

### Update Docker Images

Update base images:

```bash
# Update default image
docker pull frugan/wokenv:latest

# Update specific version
docker pull frugan/wokenv:node20-alpine-wpenv10

# Update all Wokenv images
docker images | grep frugan/wokenv | awk '{print $1":"$2}' | xargs -L1 docker pull
```

## Update Projects

### Update Project Dependencies

**Update npm packages:**
```bash
wokenv install-node
```

**Update composer packages:**
```bash
wokenv composer-update
```

**Update both:**
```bash
wokenv composer-update
wokenv install-node
```

### Update WordPress

WordPress is managed by wp-env. To update:

**Update WordPress core:**
```bash
wokenv cli -- wp core update
```

**Update all plugins:**
```bash
wokenv cli -- wp plugin update --all
```

**Update all themes:**
```bash
wokenv cli -- wp theme update --all
```

**Update specific plugin:**
```bash
wokenv cli -- wp plugin update query-monitor
```

### Update PHP Version

Change PHP version in `.wp-env.json`:

```json
{
  "phpVersion": "8.4"
}
```

Restart:
```bash
wokenv destroy
wokenv start
```

### Update wp-env Version

Wokenv Docker images track wp-env major versions. To use a newer wp-env:

1. **Check available images:**

Visit <https://hub.docker.com/r/frugan/wokenv/tags>

2. **Update wokenv.yml:**

```yaml
image:
  node: 20
  variant: alpine
  wpenv: 11  # New major version
```

3. **Restart:**

```bash
wokenv destroy
wokenv start
```

## Version Compatibility

### Project Version Tracking

Projects track which Wokenv version they were created with:

```yaml
# wokenv.yml
version: "0.1.0"
```

### Handling Version Mismatches

When you update Wokenv, you might see:

```
Version Mismatch Warning
Project uses Wokenv v0.1.0
Current Wokenv version: v0.2.0
```

**Options:**

1. **Update project (recommended):**

Edit `wokenv.yml`:
```yaml
version: "0.2.0"
```

Check [CHANGELOG.md](https://github.com/wokenv/wokenv/blob/main/CHANGELOG.md) for breaking changes.

2. **Continue with warning:**

Press `y` to proceed. May encounter compatibility issues.

3. **Downgrade Wokenv:**

```bash
cd ~/.wokenv
git checkout v0.1.0
```

### Breaking Changes

Major version updates (e.g., 0.x → 1.x) may include breaking changes.

**Before updating:**
1. Read [CHANGELOG.md](https://github.com/wokenv/wokenv/blob/main/CHANGELOG.md)
2. Test in development project first
3. Update production projects gradually

## Update Checklist

### Monthly Maintenance

- [ ] Update Wokenv: `wokenv self-update`
- [ ] Update Docker images: `docker pull frugan/wokenv:latest`
- [ ] Update project dependencies: `wokenv composer-update`
- [ ] Update WordPress core: `wokenv cli -- wp core update`
- [ ] Update plugins: `wokenv cli -- wp plugin update --all`
- [ ] Run tests: `wokenv test`

### Before Production Deploy

- [ ] Test locally with latest versions
- [ ] Run full test suite
- [ ] Backup database
- [ ] Update staging environment
- [ ] Test staging thoroughly
- [ ] Deploy to production

## Rollback

### Rollback Wokenv

If an update causes issues:

```bash
cd ~/.wokenv
git log --oneline
git checkout <previous-commit>
```

### Rollback Docker Image

```bash
# List available versions
docker images frugan/wokenv

# Use specific version
echo "WOKENV_IMAGE=frugan/wokenv:node20-alpine-wpenv10" >> .env

# Restart
wokenv restart
```

### Rollback WordPress

```bash
# Restore database backup
wokenv cli -- wp db import backup.sql

# Downgrade core
wokenv cli -- wp core update --version=6.3 --force

# Downgrade plugin
wokenv cli -- wp plugin update query-monitor --version=3.15.0
```

## Staying Informed

### Check for Updates

Wokenv checks for updates automatically (once per day).

Manual check:

```bash
cd ~/.wokenv
git fetch origin main
git log --oneline HEAD..origin/main
```

### Release Notifications

**Watch the repository:**

1. Go to <https://github.com/wokenv/wokenv>
2. Click "Watch" → "Custom" → "Releases"
3. Get notified of new releases

**RSS Feed:**

Subscribe to releases: <https://github.com/wokenv/wokenv/releases.atom>

### Changelog

Read what's new: <https://github.com/wokenv/wokenv/blob/main/CHANGELOG.md>

## Update Frequency Recommendations

### Wokenv Core

- **Patch updates** (0.1.0 → 0.1.1): Update immediately
- **Minor updates** (0.1.0 → 0.2.0): Update monthly
- **Major updates** (0.x → 1.0): Review changelog, test thoroughly

### Docker Images

- **Security updates**: Update weekly
- **Feature updates**: Update monthly
- **Major versions**: Test before updating

### Project Dependencies

- **npm packages**: Update monthly
- **composer packages**: Update monthly
- **WordPress core**: Update on release (after testing)
- **Plugins**: Update when stable

## Automated Updates

### GitHub Actions

Create `.github/workflows/update.yml`:

```yaml
name: Update Dependencies

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Wokenv
        run: |
          curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash
      
      - name: Update dependencies
        run: |
          wokenv install
          wokenv composer-update
      
      - name: Run tests
        run: wokenv test
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'chore: update dependencies'
          title: 'Update Dependencies'
          branch: update-dependencies
```

### Dependabot

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  # npm dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
  
  # Composer dependencies
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
  
  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Common Update Issues

### Update Fails

**Problem:**
```
Error: git pull failed
```

**Solution:**

```bash
cd ~/.wokenv
git status
git stash
git pull
git stash pop
```

### Containers Won't Start After Update

**Problem:**

Containers fail to start after updating.

**Solution:**

```bash
# Rebuild everything
wokenv destroy
docker pull frugan/wokenv:latest
wokenv start
```

### Permission Issues After Update

**Problem:**

File permission errors after update.

**Solution:**

```bash
wokenv fix-perms
```

### Database Issues After Update

**Problem:**

Database errors after updating WordPress.

**Solution:**

```bash
# Update database
wokenv cli -- wp core update-db
```

## Best Practices

1. **Backup before major updates**
```bash
wokenv cli -- wp db export backup-$(date +%Y%m%d).sql
```

2. **Test updates in development first**

Never update production directly.

3. **Read changelogs**

Always check CHANGELOG.md for breaking changes.

4. **Update incrementally**

Update one component at a time for easier troubleshooting.

5. **Keep lockfiles**

Commit `package-lock.json` and `composer.lock` for reproducible builds.

6. **Monitor after updates**

Watch for errors in:
- WordPress debug log
- Docker logs
- Application performance

## Next Steps

- Read [Configuration](configuration.md) for customization options
- Check [Troubleshooting](troubleshooting.md) if you encounter issues
- See [FAQ](faq.md) for common questions
