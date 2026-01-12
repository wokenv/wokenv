# Frequently Asked Questions

## General

### What is Wokenv?

Wokenv is a Docker-based WordPress development environment that simplifies plugin, theme, and core development using [@wordpress/env](https://github.com/WordPress/gutenberg/tree/trunk/packages/env).

### Why use Wokenv instead of vanilla wp-env?

- **Docker-in-Docker setup**: No need to install Node.js on host
- **Pre-configured**: Ready-to-use setup with best practices
- **Makefile workflow**: Simple, memorable commands
- **Permission handling**: Automatic handling of Docker permission issues
- **Composer integration**: PHP version-aware plugin management
- **Two variants**: Choose between standard or pre-patched images

### Is Wokenv production-ready?

No. Wokenv is designed exclusively for local development. Never use it in production environments.

## Installation

### Where does Wokenv install?

By default, Wokenv installs to `~/.wokenv` in your home directory. The installation is centralized so you can use it across multiple projects.

### Can I use Wokenv without the curl installer?

Yes! You can manually clone the repository:
```bash
git clone https://github.com/wokenv/wokenv.git ~/.wokenv
cd ~/.wokenv
chmod +x bin/wokenv
ln -s "$(pwd)/bin/wokenv" ~/.local/bin/wokenv
```

### Do I need Node.js installed?

No! Wokenv runs everything inside Docker containers, including Node.js.

### How do I initialize a new project?

Simply run:
```bash
cd /path/to/your-project
wokenv init
```

The wizard will guide you through the setup process.

## Configuration

### Which Docker image should I use?

- **`wokenv/wokenv:latest`**: Standard image, requires manual patching if needed
- **`wokenv/wokenv:patched`**: Pre-patched image, ready to use

We recommend starting with `:patched` unless you have specific requirements.

### Where do I configure environment variables?

Create a `.env` file in your project directory:
```bash
USER_ID=$(id -u)
GROUP_ID=$(id -g)
CUSTOM_IMAGE=wokenv/wokenv:patched
```

### Can I customize the WordPress environment?

Yes! Use `.wp-env.json` to configure:
- PHP version
- WordPress version
- Themes and plugins
- Port numbers
- And more

See [@wordpress/env documentation](https://github.com/WordPress/gutenberg/tree/trunk/packages/env) for all options.

## Usage

### Why does `make start` take so long the first time?

The first start downloads WordPress, sets up the database, and installs dependencies. Subsequent starts are much faster.

### Can I use multiple WordPress versions?

Yes! Change the PHP version in `.wp-env.json`:
```json
{
  "phpVersion": "8.0"
}
```

Then restart:
```bash
make destroy
make start
```

### How do I add development plugins?

Add them to `composer.json`:
```json
{
  "require-dev": {
    "wpackagist-plugin/query-monitor": "^3.16"
  }
}
```

Then run:
```bash
make composer
make restart
```

### Can I use Wokenv for themes?

Absolutely! Just point `.wp-env.json` to your theme directory:
```json
{
  "themes": [
    "."
  ]
}
```

## Troubleshooting

### I get "permission denied" errors

Run:
```bash
make fix-perms
```

If that doesn't work, check your Docker configuration for `userns-remap` (which is not compatible with Wokenv).

### Port 8888 is already in use

Change the port in `.wp-env.json`:
```json
{
  "port": 8890
}
```

### The environment won't start

Try:
```bash
make destroy
make start
```

If issues persist, check Docker logs:
```bash
docker logs $(docker ps -q --filter "name=wordpress")
```

### I updated Wokenv but changes aren't applying

Pull the latest Docker image:
```bash
docker pull wokenv/wokenv:latest
# or
docker pull wokenv/wokenv:patched
```

### How do I completely reset everything?

```bash
make destroy
make clean
rm -rf ~/.wp-env
make install
make start
```

## Docker

### Why Docker-in-Docker?

This approach allows you to run wp-env (which creates its own Docker containers) inside a Docker container, providing complete isolation and avoiding the need for Node.js installation on your host.

### Does Wokenv work with Docker Desktop?

Yes! Wokenv works with Docker Desktop on macOS, Windows, and Linux.

### Does Wokenv work with userns-remap?

**No.** Wokenv is incompatible with Docker's `userns-remap` configuration due to how wp-env handles permissions.

### Can I use Podman instead of Docker?

Not currently tested, but it might work with Docker compatibility mode. Contributions welcome!

## Advanced

### Can I extend the Docker image?

Yes! Create your own Dockerfile:
```dockerfile
FROM wokenv/wokenv:latest
RUN npm install -g your-tool
```

### Can I use it for multisite?

Yes! Configure in `.wp-env.json`:
```json
{
  "config": {
    "WP_ALLOW_MULTISITE": true
  }
}
```

### How do I run multiple projects simultaneously?

Use different ports for each project. Modify `.wp-env.json`:
```json
{
  "port": 8890,
  "testsPort": 8891
}
```

## Contributing

### How can I contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Where do I report bugs?

Open an issue on [GitHub](https://github.com/wokenv/wokenv/issues).

## Support

### Where can I get help?

- [GitHub Issues](https://github.com/wokenv/wokenv/issues)
- [README Documentation](README.md)

### Is commercial support available?

Not currently, but feel free to reach out for consulting opportunities.

---

**Don't see your question?** [Open an issue](https://github.com/wokenv/wokenv/issues/new) and we'll add it to the FAQ!
