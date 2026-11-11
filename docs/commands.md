# Commands

Run every command from your project directory, or from any of its subdirectories.

## Environment

| Command                        | Description                                                                 |
| ------------------------------ | --------------------------------------------------------------------------- |
| `wokenv init [--type <type>]`  | Create `wokenv.yml`. `--force` overwrites an existing file                  |
| `wokenv start [options]`       | Start WordPress. Accepts the options of `wp-env start`                      |
| `wokenv stop`                  | Stop WordPress and Mailpit, and free the ports. Data is kept                |
| `wokenv restart`               | `stop`, then `start`                                                        |
| `wokenv status`                | Show the state of the environment and its URLs                              |
| `wokenv logs [environment]`    | Show PHP and Docker logs                                                    |
| `wokenv reset [environment]`   | Reset the WordPress database                                                |
| `wokenv destroy [--yes]`       | Delete containers, volumes, database and images. Your project is not touched |

Useful `start` options:

```bash
wokenv start --xdebug                  # Xdebug in "debug" mode
wokenv start --xdebug=debug,coverage   # Choose the Xdebug modes
wokenv start --spx                     # SPX profiler
wokenv start --update                  # Download source updates and reconfigure WordPress
```

Change `wokenv.yml` whenever you like, then run `wokenv start` again: wp-env reconfigures WordPress when its configuration changed.

## Tools

| Command                           | Runs in             | Description                                 |
| --------------------------------- | ------------------- | ------------------------------------------- |
| `wokenv wp <args>`                | `cli` container     | WP-CLI                                      |
| `wokenv composer <args>`          | `cli` container     | Composer, in your project directory         |
| `wokenv phpunit [args]`           | `tests-cli`         | PHPUnit, in your project directory          |
| `wokenv shell [container]`        | `cli` by default    | Interactive Bash                            |
| `wokenv run <container> <cmd>`    | any wp-env container | Same as `wp-env run`                       |
| `wokenv npm` / `npx` / `node`     | Wokenv container    | Node.js tooling, in the current directory   |
| `wokenv wp-env <args>`            | Wokenv container    | Call wp-env directly                        |

```bash
wokenv wp plugin install query-monitor --activate
wokenv wp option get siteurl
wokenv composer require --dev phpunit/phpunit
wokenv npm ci && wokenv npm run build
wokenv run cli --env-cwd=wp-content/themes/my-theme -- ls
wokenv shell wordpress
```

`wokenv phpunit` needs wp-env's tests environment, which `wokenv init` turns off: remove `testsEnvironment: false` from `wokenv.yml` to use it.

## Wokenv

| Command              | Description                                         |
| -------------------- | --------------------------------------------------- |
| `wokenv doctor`      | Check that this machine can run Wokenv              |
| `wokenv self-update` | Update Wokenv and its Docker image                  |
| `wokenv version`     | Show the Wokenv version, and wp-env's in a project  |
| `wokenv help`        | Show the command list                               |
