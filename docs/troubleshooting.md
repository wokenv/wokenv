# Troubleshooting

Start with `wokenv doctor`: it checks Docker, Docker Compose, the daemon and the socket.

## "No wokenv.yml found"

Commands must run inside a project. Create the file with `wokenv init`.

## "Do not run wokenv as root"

wp-env maps the current user into its containers, and Apache refuses to run as root. Use a regular user that can reach Docker (on Linux, a member of the `docker` group).

## "Cannot reach the Docker daemon" or "permission denied" on the socket

- Check that Docker is running: `docker info`.
- On Linux, add your user to the `docker` group and log in again: `sudo usermod -aG docker "$USER"`.
- If your socket is not at `/var/run/docker.sock`, set `WOKENV_DOCKER_SOCKET`.

## A port is already allocated

Another process, or another Wokenv project, uses the port. Change it in `wokenv.yml`:

```yaml
mailpit: 8026

wp-env:
  port: 8890
  phpmyadminPort: 9001
```

When the tests environment is enabled, `phpmyadminPort` at the top level applies to both environments and clashes with itself: set it under `env.development` instead.

## Files are owned by the wrong user

Wokenv does not support Docker with `userns-remap` or rootless Docker: the user inside the containers does not map to your user on the host. `wokenv doctor` warns about both.

## Changes to wokenv.yml are ignored

Run `wokenv start` again. To force wp-env to download sources and reconfigure WordPress, use `wokenv start --update`.

## Emails do not reach Mailpit

- Mailpit is connected to WordPress by `wokenv start`. If you started the containers in another way, run `wokenv start` again.
- Check that the must-use plugin is loaded: `wokenv wp plugin list --status=must-use` must list `wokenv-mailpit`.
- If you map `wp-content` or `wp-content/mu-plugins`, copy `~/.wokenv/lib/mu-plugins/wokenv-mailpit.php` into your own must-use plugins.
- Only `wp_mail()` is routed. PHP's `mail()` function is not.

## A lifecycle script cannot find a command

Lifecycle scripts run in the Wokenv container, which has `node`, `npm`, `git` and `docker` only. Run PHP tools through wp-env: `wp-env run cli composer install`.

## Start over

```bash
wokenv destroy   # deletes containers, volumes and the database of this project
wokenv start
```

To remove everything Wokenv stored for all projects, destroy each project, then delete `~/.wokenv/var`.

## Getting help

Wokenv runs an unmodified wp-env: if a problem also happens with `npx wp-env` on a machine with Node.js, report it to [Gutenberg](https://github.com/WordPress/gutenberg/issues). Otherwise open an issue at [wokenv/wokenv](https://github.com/wokenv/wokenv/issues) with the output of `wokenv doctor`.
