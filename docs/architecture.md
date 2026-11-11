# Architecture

Wokenv is a thin layer around the official [wp-env](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/). It does two things: it runs wp-env from a container, so that Node.js is not needed on the host, and it lets a project describe its environment in a single file.

## Overview

```
 Host                                Docker daemon
┌──────────────────────┐            ┌──────────────────────────────────────────┐
│ wokenv (bash)        │  compose   │ Wokenv container (frugan/wokenv)         │
│  ~/.wokenv/bin       ├───────────►│  Node.js + wp-env, runs as your user     │
│                      │    run     │  mounts: project, state, Docker socket   │
│ your-plugin/         │            └───────────────────┬──────────────────────┘
│  └── wokenv.yml      │                                │ docker compose (socket)
└──────────────────────┘            ┌───────────────────▼──────────────────────┐
                                    │ wp-env project                           │
                                    │  wordpress, cli, mysql, phpmyadmin,      │
                                    │  tests-* ... + mailpit (joined by Wokenv)│
                                    └──────────────────────────────────────────┘
```

1. `wokenv` finds `wokenv.yml`, walking up from the current directory.
2. If `wokenv.yml` changed, a short-lived container runs `lib/wokenv-config.cjs`, which writes a regular `.wp-env.json` to the project's state directory. No network and no Docker socket are given to this step.
3. `wokenv` runs wp-env in the Wokenv container with `--config` pointing at that file. The container is created for the command and removed when it ends.
4. wp-env builds and starts the WordPress containers through the mounted Docker socket. They are siblings of the Wokenv container, not children: they keep running after it exits.
5. After `start`, Wokenv connects its Mailpit container to the network wp-env created, under the name `mailpit`.

## Repositories

| Repository                                         | Content                                                |
| -------------------------------------------------- | ------------------------------------------------------ |
| [wokenv/wokenv](https://github.com/wokenv/wokenv)  | The `wokenv` command, installed in `~/.wokenv`         |
| [wokenv/base](https://github.com/wokenv/base)      | The `frugan/wokenv` Docker image: Node.js, Docker CLI, wp-env |

The image contains no Wokenv logic besides its entrypoint: `lib/` is mounted from `~/.wokenv` at run time, so updating Wokenv does not require a new image.

## Files

```
~/.wokenv/
├── bin/wokenv                    The command (linked from ~/.local/bin)
├── docker-compose.yml            Wokenv container and Mailpit, shared by all projects
├── lib/
│   ├── wokenv-config.cjs         wokenv.yml → .wp-env.json
│   └── mu-plugins/               Must-use plugin that routes mail to Mailpit
└── var/                          Runtime data, not part of the installation
    ├── home/                     HOME of the Wokenv container (npm cache)
    └── projects/<name>-<id>/
        ├── .wp-env.json          Generated wp-env configuration
        ├── compose.override.json Generated mounts and Mailpit port
        ├── project.env           Facts the command needs (type, paths, ports)
        └── wp-env/               wp-env's own work directory (WP_ENV_HOME)
```

Your project directory only contains `wokenv.yml`.

## Design constraints

### Paths are identical on the host and in the container

wp-env writes a `docker-compose.yml` whose bind mounts are resolved by the Docker daemon, that is, on the host. Every path wp-env sees must therefore be the same inside the Wokenv container and outside of it. This is why the project is mounted at its own host path, why `WP_ENV_HOME` points inside the state directory instead of the container's home, and why the generated configuration only contains absolute paths.

### wp-env runs as your user

The entrypoint of the image creates a user with your UID and GID, adds it to the group that owns the Docker socket, and drops privileges before running anything. wp-env reads that user to build its images and to set the Apache user, so files written by WordPress, WP-CLI or Composer in your project belong to you.

### wp-env is never patched

Wokenv only uses wp-env's public interface: the configuration file, the `--config` option, `WP_ENV_HOME` and the command line. Nothing in the image modifies wp-env's sources, so a new wp-env release cannot break a patch.

### The Docker socket

Mounting the Docker socket gives the Wokenv container control of the Docker daemon, which is equivalent to root on the host. wp-env needs it to manage containers. The configuration step, which is the only one that parses project files before wp-env runs, is isolated from both the socket and the network.
