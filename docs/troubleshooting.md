# Troubleshooting

Solutions to common issues when using Wokenv.

## Installation Issues

### git not found

**Problem:**
```
Error: git is not installed.
```

**Solution:**

Install git:

**macOS:**
```bash
brew install git
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install git
```

**Fedora/RHEL:**
```bash
sudo dnf install git
```

### Docker not found or daemon not running

**Problem:**
```
Error: Docker is not installed.
# or
Error: Docker daemon is not running.
```

**Solution:**

1. Install Docker Desktop from <https://docs.docker.com/get-docker/>
2. Start Docker Desktop
3. Verify: `docker ps`

### wokenv command not found

**Problem:**
```bash
wokenv: command not found
```

**Solution:**

**Option 1: Add to PATH (recommended)**

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

**Option 2: Create symlink manually**

```bash
mkdir -p ~/.local/bin
ln -sf ~/.wokenv/bin/wokenv ~/.local/bin/wokenv
```

**Option 3: Use full path**

```bash
~/.wokenv/bin/wokenv start
```

## Permission Issues

### Permission denied errors

**Problem:**
```
Permission denied: /var/www/html/wp-content/...
```

**Solution:**

```bash
wokenv fix-perms
```

If that doesn't work:

```bash
# Fix local files
sudo chown -R $(id -u):$(id -g) .

# Restart
wokenv restart
```

### Cannot create directory

**Problem:**
```
mkdir: cannot create directory '/home/node/.wp-env': Permission denied
```

**Solution:**

```bash
# Create directory with correct permissions
mkdir -p ~/.wp-env
chmod 755 ~/.wp-env

# Restart
wokenv restart
```

### Docker socket permission denied

**Problem:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**

**Linux:**
```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or use newgrp to apply immediately
newgrp docker
```

**macOS/Windows:**
Make sure Docker Desktop is running.

## Port Conflicts

### Port already in use

**Problem:**
```
Error: Port 8888 is already in use
```

**Solution:**

**Option 1: Change WordPress ports**

Edit `.wp-env.json`:
```json
{
  "port": 8890,
  "testsPort": 8891
}
```

**Option 2: Change service ports**

Edit `.env`:
```bash
MAILPIT_WEB_PORT=8026
PHPMYADMIN_PORT=9001
```

**Option 3: Stop conflicting service**

Find what's using the port:

```bash
# macOS/Linux
lsof -i :8888

# Or
netstat -tulpn | grep 8888
```

Kill the process:
```bash
kill -9 <PID>
```

### Docker Compose port conflict

**Problem:**
```
Error: Address already in use
```

**Solution:**

Check if another project is running:

```bash
docker ps
```

Stop conflicting containers:

```bash
# Stop specific project
cd /path/to/other-project
wokenv stop

# Or stop all
docker stop $(docker ps -q)
```

## Environment Issues

### Environment won't start

**Problem:**
```
Error starting environment
```

**Solution:**

Try these steps in order:

1. **Check Docker daemon:**
```bash
docker ps
```

2. **Destroy and restart:**
```bash
wokenv destroy
wokenv start
```

3. **Check Docker resources:**
- Open Docker Desktop → Settings → Resources
- Increase Memory to at least 4GB
- Increase Disk Image Size if needed

4. **Check logs:**
```bash
docker logs $(docker ps -q --filter "name=wordpress")
```

5. **Complete cleanup:**
```bash
wokenv destroy
wokenv clean
rm -rf ~/.wp-env
wokenv start
```

### wp-env fails to start

**Problem:**
```
Error: wp-env start failed
```

**Solution:**

1. **Check Node.js in container:**
```bash
docker run --rm frugan/wokenv:latest node --version
docker run --rm frugan/wokenv:latest npm --version
```

2. **Clear wp-env cache:**
```bash
rm -rf ~/.wp-env
```

3. **Check .wp-env.json syntax:**
```bash
# Validate JSON
cat .wp-env.json | python3 -m json.tool
```

4. **Try minimal config:**
```json
{
  "core": null,
  "phpVersion": "8.4"
}
```

### Container keeps restarting

**Problem:**
```
Container is restarting repeatedly
```

**Solution:**

1. **Check container logs:**
```bash
docker logs <container-name>
```

2. **Inspect container:**
```bash
docker inspect <container-name>
```

3. **Stop automatic restart:**
```bash
docker update --restart=no <container-name>
docker stop <container-name>
```

4. **Remove and recreate:**
```bash
wokenv destroy
wokenv start
```

## Database Issues

### Database connection errors

**Problem:**
```
Error establishing a database connection
```

**Solution:**

1. **Wait for MySQL to start:**

MySQL takes 10-20 seconds to fully start. Wait and try again.

2. **Check MySQL container:**
```bash
docker ps | grep mysql
docker logs $(docker ps -q --filter "name=mysql")
```

3. **Reset environment:**
```bash
wokenv destroy
wokenv start
```

4. **Verify database credentials:**

Default credentials:
- Host: `127.0.0.1` (or container name for internal connections)
- Database: `wordpress`
- User: `root`
- Password: `password`

### Cannot import database

**Problem:**
```
Error: wp db import failed
```

**Solution:**

1. **Check file exists:**
```bash
ls -lh backup.sql
```

2. **Check file size:**

Large files may timeout. Increase timeout:

```bash
wokenv cli -- wp config set DB_HOST 'mysql:3306' --type=constant
```

3. **Import in chunks:**
```bash
split -l 10000 backup.sql chunk_

for file in chunk_*; do
    wokenv cli -- wp db query "$(cat $file)"
done

rm chunk_*
```

### Database too large

**Problem:**
```
Error: max_allowed_packet too small
```

**Solution:**

Increase MySQL packet size in `.wp-env.json`:

```json
{
  "config": {
    "DB_COLLATE": "",
    "DB_CHARSET": "utf8mb4"
  }
}
```

Or use CLI:

```bash
wokenv mysql
SET GLOBAL max_allowed_packet=1073741824;  # 1GB
exit
```

## Network Issues

### Cannot reach services

**Problem:**
```
Cannot access WordPress at localhost:8888
```

**Solution:**

1. **Check containers are running:**
```bash
docker ps
```

2. **Check ports are exposed:**
```bash
docker ps | grep 8888
```

3. **Try 127.0.0.1 instead:**
```
http://127.0.0.1:8888
```

4. **Check firewall:**

macOS:
```bash
System Preferences → Security & Privacy → Firewall
```

Linux:
```bash
sudo ufw status
sudo ufw allow 8888
```

### Network connect error

**Problem:**
```
Error: Network connect failed
```

**Solution:**

1. **Recreate network:**
```bash
wokenv stop
docker network rm $(docker network ls -q --filter "name=wokenv")
wokenv start
```

2. **Connect containers manually:**
```bash
wokenv connect-network
```

## Version Issues

### Version mismatch warning

**Problem:**
```
Version Mismatch Warning
Project uses Wokenv v0.1.0
Current Wokenv version: v0.2.0
```

**Solution:**

**Option 1: Update project (recommended)**

Update `wokenv.yml`:
```yaml
version: "0.2.0"
```

Check for breaking changes in CHANGELOG.md.

**Option 2: Continue with warning**

Press `y` to continue. May cause compatibility issues.

**Option 3: Downgrade Wokenv**

```bash
cd ~/.wokenv
git checkout v0.1.0
```

### Cannot update Wokenv

**Problem:**
```
Error: git pull failed
```

**Solution:**

1. **Check for local changes:**
```bash
cd ~/.wokenv
git status
```

2. **Stash changes:**
```bash
git stash
git pull
git stash pop
```

3. **Or reset:**
```bash
git fetch --all
git reset --hard origin/main
```

## Docker Issues

### Docker Compose version conflict

**Problem:**
```
docker-compose: unsupported Compose file version
```

**Solution:**

Update Docker Compose:

```bash
# Check current version
docker-compose --version

# Update via Docker Desktop (recommended)
# Or via pip
pip3 install --upgrade docker-compose
```

### Out of disk space

**Problem:**
```
Error: No space left on device
```

**Solution:**

1. **Clean Docker:**
```bash
docker system prune -a
```

2. **Remove unused volumes:**
```bash
docker volume prune
```

3. **Remove unused images:**
```bash
docker image prune -a
```

4. **Increase Docker disk size:**

Docker Desktop → Settings → Resources → Disk Image Size

### User namespace remapping incompatibility

**Problem:**
```
Permission errors with userns-remap enabled
```

**Solution:**

Wokenv is **not compatible** with Docker's `userns-remap` feature.

**Option 1: Disable userns-remap (recommended)**

Edit `/etc/docker/daemon.json`:

```json
{
  // Remove or comment out userns-remap
  // "userns-remap": "default"
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

**Option 2: Use different development tool**

If you require user namespace remapping for security, Wokenv is not suitable for your setup.

## Common Errors

### "Cannot find module '@wordpress/env'"

**Problem:**
```
Error: Cannot find module '@wordpress/env'
```

**Solution:**

This should not happen as wp-env is pre-installed in the container. If it does:

1. **Pull latest image:**
```bash
docker pull frugan/wokenv:latest
```

2. **Recreate container:**
```bash
wokenv destroy
wokenv start
```

### "Command not found" in scripts

**Problem:**
```
npm run env:start
Error: wp-env: command not found
```

**Solution:**

The container should have wp-env in PATH. If not:

```bash
# Check wp-env location
docker run --rm frugan/wokenv:latest which wp-env

# Should output: /usr/local/bin/wp-env or similar
```

If missing, pull latest image:

```bash
docker pull frugan/wokenv:latest
wokenv restart
```

### "EACCES: permission denied"

**Problem:**
```
npm ERR! Error: EACCES: permission denied
```

**Solution:**

```bash
# Fix ownership
wokenv fix-perms

# Or manually
sudo chown -R $(id -u):$(id -g) node_modules package-lock.json
```

## Getting More Help

### Enable Debug Mode

Add to `.wp-env.json`:

```json
{
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true,
    "WP_DEBUG_DISPLAY": false
  }
}
```

View debug log:

```bash
wokenv cli -- wp eval 'echo file_get_contents(WP_CONTENT_DIR . "/debug.log");'
```

### Check System Info

```bash
# Wokenv info
wokenv info

# Docker info
docker --version
docker-compose --version
docker info

# System info
uname -a
```

### Collect Logs

```bash
# Container logs
docker logs $(docker ps -q --filter "name=wordpress") > wordpress.log
docker logs $(docker ps -q --filter "name=mysql") > mysql.log

# Environment info
wokenv info > environment.txt

# System info
docker info > docker-info.txt
```

### Reset Everything

Nuclear option - complete reset:

```bash
# Stop and remove everything
wokenv destroy
wokenv clean

# Remove Wokenv cache
rm -rf ~/.wp-env

# Remove Docker volumes
docker volume prune -f

# Reinstall dependencies
wokenv install

# Start fresh
wokenv start
```

## Reporting Issues

If none of these solutions work:

1. **Search existing issues**: <https://github.com/wokenv/wokenv/issues>
2. **Check FAQ**: [faq.md](faq.md)
3. **Open new issue**: <https://github.com/wokenv/wokenv/issues/new>

Include:
- Operating system and version
- Docker version
- Wokenv version
- Error messages (full output)
- Steps to reproduce
- Relevant configuration files (wokenv.yml, .wp-env.json)

## Prevention

### Regular Maintenance

```bash
# Weekly: Clean Docker
docker system prune

# Monthly: Update Wokenv
wokenv self-update

# As needed: Update images
docker pull frugan/wokenv:latest
```

### Best Practices

1. **Commit configuration files** (wokenv.yml, .wp-env.json)
2. **Use .gitignore** for .env and local overrides
3. **Document custom services** in README
4. **Keep WordPress and plugins updated**
5. **Test before deploying** to production
