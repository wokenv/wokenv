# Wokenv Architecture

Technical documentation of Wokenv's internal architecture and design decisions.

## Overview

Wokenv is a centralized Docker-in-Docker wrapper around [@wordpress/env](https://github.com/WordPress/gutenberg/tree/trunk/packages/env) that provides:
1. Isolated WordPress development environments
2. Automatic permission handling
3. Centralized configuration with per-project customization
4. Dynamic network connection for additional services
5. Version compatibility management
6. Simplified workflow via CLI and Makefile

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│ Host Machine                                                     │
│                                                                  │
│  ~/.wokenv/ (Centralized)                                        │
│  ├── docker-compose.yml     ← Controls all services             │
│  ├── Makefile               ← Business logic                     │
│  └── bin/wokenv            ← User CLI                            │
│                                                                  │
│  /your/project/ (Per-Project)                                    │
│  ├── wokenv.yml             ← Versioned config                   │
│  ├── .env                   ← Local overrides                    │
│  └── docker-compose.override.yml ← Custom services (optional)    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Shared Docker Network: {project-name}-network            │  │
│  │                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │ Wokenv       │  │ Mailpit      │  │ phpMyAdmin   │  │  │
│  │  │ Container    │  │ (Email)      │  │ (Database)   │  │  │
│  │  │ (Node+wp-env)│  │ Port 8025    │  │ Port 9000    │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │  │
│  │         │                                                 │  │
│  │         │ Creates via wp-env:                            │  │
│  │         ↓                                                 │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │ WordPress    │  │ WordPress    │  │ MySQL        │  │  │
│  │  │ (Production) │  │ (Tests)      │  │ Container    │  │  │
│  │  │ Port 8888    │  │ Port 8889    │  │ (Internal)   │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │  │
│  │         ↑                ↑                   ↑           │  │
│  │         └────────────────┴───────────────────┘           │  │
│  │            Connected dynamically via Makefile            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Volumes:                                                       │
│  - /var/run/docker.sock (Docker API access)                    │
│  - $PROJECT_DIR (current project)                              │
│  - $HOME/.wp-env (WordPress cache, shared across projects)     │
└──────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Centralized docker-compose.yml

**Location:** `~/.wokenv/docker-compose.yml`

**Purpose:** Single source of truth for all Docker services across all projects.

**Services Included:**
- **wokenv**: Main container with Node.js + wp-env
- **mailpit**: Email testing service (always available)
- **phpmyadmin**: Database management UI (always available)

**Why Centralized:**
- ✅ **Updates propagate**: Fix once, all projects benefit
- ✅ **No duplication**: One config, many projects
- ✅ **Consistency**: Same environment everywhere
- ✅ **Easy maintenance**: Update services in one place

**How Projects Use It:**
```bash
# Makefile references centralized compose file
DOCKER_COMPOSE := docker-compose -f $(HOME)/.wokenv/docker-compose.yml

# If local override exists, include it
ifneq (,$(wildcard docker-compose.override.yml))
    DOCKER_COMPOSE += -f docker-compose.override.yml
endif
```

### 2. Per-Project Configuration

#### wokenv.yml (Versioned)

**Purpose:** Project metadata and Wokenv-specific configuration.

**Contains:**
```yaml
version: "1.0.0"         # Wokenv version compatibility
project:
  type: plugin           # Project type
  slug: my-plugin        # Project identifier
image:
  node: 20              # Docker image settings
  variant: alpine
  wpenv: 10
```

**Why Separate from .env:**
- Versioning metadata is Wokenv-specific, not Docker Compose standard
- Can track which Wokenv version project was created with
- Enables migration automation when Wokenv updates

#### .env (Local Only)

**Purpose:** Runtime variables that vary per machine.

**Contains:**
```bash
USER_ID=1000                    # User mapping
GROUP_ID=1000                   # Group mapping
COMPOSE_PROJECT_NAME=my-plugin  # Container prefix
MAILPIT_WEB_PORT=8025          # Service ports
PHPMYADMIN_PORT=9000
```

**Why Gitignored:**
- User IDs vary between machines
- Port preferences are personal
- Allows each developer to customize locally

#### docker-compose.override.yml (Optional, Local Only)

**Purpose:** Add custom services or override defaults.

**Example:**
```yaml
services:
  redis:
    image: redis:alpine
    networks:
      - wokenv
  
  # Override wokenv image for testing
  wokenv:
    image: frugan/wokenv:node22-alpine-wpenv10
```

**Why It Works:**
- Docker Compose automatically merges base + override
- Standard Docker pattern, no custom logic needed
- Allows per-developer customizations

### 3. Makefile (Centralized Logic)

**Location:** `~/.wokenv/Makefile`

**Purpose:** Business logic for all Wokenv operations.

**Key Responsibilities:**
1. **Parse wokenv.yml**: Extract image config, project settings
2. **Load .env**: Override with local runtime values
3. **Construct docker-compose command**: Include base + override
4. **Dynamic network connection**: Connect wp-env containers to shared network
5. **Permission management**: Fix file ownership after wp-env operations

**Architecture:**
```makefile
# Parse wokenv.yml
WOKENV_NODE := $(shell grep ... wokenv.yml ...)
WOKENV_IMAGE := frugan/wokenv:node$(WOKENV_NODE)-...

# Load .env overrides
-include .env

# Export for docker-compose
export WOKENV_IMAGE
export COMPOSE_PROJECT_NAME

# Build docker-compose command
DOCKER_COMPOSE := docker-compose -f $(HOME)/.wokenv/docker-compose.yml
ifneq (,$(wildcard docker-compose.override.yml))
    DOCKER_COMPOSE += -f docker-compose.override.yml
endif

# Targets use $(DOCKER_COMPOSE)
start:
    $(DOCKER_COMPOSE) up -d
    $(DOCKER_COMPOSE) exec wokenv npm run env:start
    $(MAKE) connect-network
```

### 4. bin/wokenv (User CLI)

**Location:** `~/.wokenv/bin/wokenv`

**Purpose:** User-friendly command-line interface.

**Responsibilities:**
1. **Version checking**: Compare project version with current Wokenv
2. **Update checks**: Notify about available updates (background)
3. **Init wizard**: Interactive project setup
4. **Self-update**: `wokenv update` command
5. **Command delegation**: Pass commands to Makefile

**Why Separate from Makefile:**
- **UX features**: Progress bars, colored output, confirmations
- **Interactive**: Wizard, prompts, yes/no questions
- **Git operations**: Clone, pull, version checks
- **Help system**: User-friendly documentation

**Flow:**
```bash
wokenv start
  ↓
1. Check project version compatibility
2. Background update check
3. Delegate to: make -f ~/.wokenv/Makefile start
```

## Data Flow

### Start Command (`wokenv start`)

```
1. User runs: wokenv start
   ↓
2. bin/wokenv checks project version (wokenv.yml)
   ↓
3. bin/wokenv delegates to: make start
   ↓
4. Makefile parses wokenv.yml + loads .env
   ↓
5. Makefile constructs docker-compose command
   ↓
6. docker-compose -f ~/.wokenv/docker-compose.yml \
                  -f docker-compose.override.yml up -d
   ↓
7. Containers start: wokenv, mailpit, phpmyadmin, custom services
   ↓
8. Inside wokenv container: npm run env:start
   ↓
9. wp-env creates: WordPress, MySQL, Tests, CLI containers
   ↓
10. Makefile connects wp-env containers to shared network
    ↓
11. Makefile fixes permissions in WordPress containers
    ↓
12. WordPress accessible at localhost:8888
    Mailpit at localhost:8025
    phpMyAdmin at localhost:9000
```

### Configuration Precedence

```
1. Hardcoded defaults in Makefile
   ↓ (overridden by)
2. wokenv.yml (project config)
   ↓ (overridden by)
3. .env (local runtime)
   ↓ (used by)
4. docker-compose.yml (base services)
   ↓ (extended by)
5. docker-compose.override.yml (custom services)
```

## Dynamic Network Connection

### The Challenge

wp-env creates containers with dynamic names:
- `{project-slug}-wordpress-1`
- `{project-slug}-mysql-1`
- `{project-slug}-tests-wordpress-1`

These containers are **not** managed by our docker-compose.yml, so they don't automatically join the shared network.

### The Solution

**Makefile dynamically detects and connects them:**

```makefile
connect-network:
    @WP_CONTAINER=$$(docker ps -q --filter "name=$(PROJECT_SLUG)-wordpress-1" | head -1); \
    MYSQL_CONTAINER=$$(docker ps -q --filter "name=$(PROJECT_SLUG)-mysql-1" | head -1); \
    if [ -n "$$WP_CONTAINER" ]; then \
        docker network connect $(NETWORK_NAME) $$WP_CONTAINER 2>/dev/null || true; \
    fi; \
    if [ -n "$$MYSQL_CONTAINER" ]; then \
        docker network connect $(NETWORK_NAME) $$MYSQL_CONTAINER 2>/dev/null || true; \
    fi
```

**Result:**
- WordPress containers can now access Mailpit (`mailpit:1025`)
- phpMyAdmin can connect to MySQL
- Custom services (Redis, Elasticsearch) are accessible from WordPress

**No wp-env patching required!**

## Permission Handling

### The Problem

Three user contexts:
1. **Host user** (e.g., UID 1000)
2. **Wokenv container** (runs as mapped user)
3. **WordPress containers** (files owned by www-data → UID 1000)

### The Solution

**entrypoint.sh** in wokenv/base:
```bash
# Create user matching host UID/GID
adduser -D -u $USER_ID -G $GROUP_NAME hostuser
# Switch to that user
exec su-exec hostuser "$@"
```

**Makefile** after wp-env creates containers:
```makefile
fix-perms:
    docker exec $WP_CONTAINER chown -R 1000:1000 /var/www/html
```

**Result:**
- Host user can read/write all files
- Container user can read/write all files
- No `sudo` required

## Version Compatibility

### Project Version Tracking

**wokenv.yml stores version:**
```yaml
version: "1.0.0"  # Wokenv version this project uses
```

**bin/wokenv checks compatibility:**
```bash
PROJECT_VERSION=$(grep "^version:" wokenv.yml | ...)
CURRENT_VERSION="1.0.0"  # Current Wokenv version

if [ "$PROJECT_MAJOR" != "$CURRENT_MAJOR" ]; then
    echo "Major version mismatch!"
    echo "Project: v$PROJECT_VERSION"
    echo "Current: v$CURRENT_VERSION"
    # Offer migration or warn
fi
```

### Migration Strategy

When Wokenv 2.0 is released:

1. **Old projects** specify `version: "1.0.0"` in wokenv.yml
2. **bin/wokenv** detects mismatch
3. **Options presented:**
   - Migrate project to 2.0 (automatic)
   - Continue with compatibility warning
   - Downgrade Wokenv to 1.0 for this session

**Result:** Projects don't break on Wokenv updates.

## File System Layout

### Centralized (~/.wokenv/)
```
~/.wokenv/
├── docker-compose.yml      # Base services
├── Makefile                # Business logic
├── bin/
│   └── wokenv             # User CLI
├── templates/
│   ├── plugin/            # Plugin templates
│   ├── theme/             # Theme templates
│   └── core/              # Core templates
├── .git/                  # Git repository
└── install.sh             # Installer
```

### Per-Project
```
/your/project/
├── wokenv.yml                      # Versioned config
├── .env.dist                       # Versioned template
├── .env                            # Local (gitignored)
├── docker-compose.override.yml     # Local (gitignored)
├── .wp-env.json                    # wp-env config
├── package.json                    # npm scripts
├── composer.json                   # PHP dependencies
└── your-plugin.php                 # Project files
```

### Shared Cache (~/.wp-env/)
```
~/.wp-env/
├── {md5-hash}-WordPress/          # Cached WordPress cores
├── {md5-hash}-plugins/            # Cached plugins
└── docker-compose.yml             # wp-env's compose file
```

## Security Considerations

### Docker Socket Access

**Risk:** Full Docker API access
**Mitigation:**
- Development only (clearly documented)
- User explicitly controls when containers run
- No automatic execution

### User Namespace Mapping

**Risk:** Creating arbitrary UID/GID users
**Mitigation:**
- Only maps host user's actual IDs
- No root password set in containers
- Users cleaned on container removal

### Centralized Configuration

**Risk:** Malicious docker-compose.yml in ~/.wokenv
**Mitigation:**
- User controls ~/.wokenv (cloned from trusted repo)
- Standard git for updates (shows diffs)
- Override mechanism for experimentation

## Performance Optimizations

### Centralized Cache
- WordPress cores cached in ~/.wp-env
- Shared across all projects
- Dramatically faster subsequent `start` commands

### Volume Strategy
- Direct mount (no copy) for instant file sync
- Named volumes for databases (persistent)
- tmpfs for temporary files (faster)

### Network Efficiency
- Single shared network per project
- No network creation overhead
- Efficient container-to-container communication

## Extensibility Points

### Custom Services

Add any Docker service:
```yaml
# docker-compose.override.yml
services:
  redis:
    image: redis:alpine
    networks:
      - wokenv
```

Automatically shares network with WordPress!

### Custom Images

Test different Wokenv versions:
```yaml
# docker-compose.override.yml
services:
  wokenv:
    image: frugan/wokenv:node22-alpine-wpenv10
```

### Makefile Extensions

Power users can add custom targets:
```makefile
# Makefile.local (optional, gitignored)
backup-db:
    @echo "Backing up database..."
    $(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db export backup.sql
```

Include in main Makefile:
```makefile
-include Makefile.local
```

## Comparison: Before vs After

### Before (Old Architecture)

```
Project A/               Project B/               Project C/
├── wokenv.yml           ├── wokenv.yml           ├── wokenv.yml
├── .env                 ├── .env                 ├── .env
├── Makefile (copy)      ├── Makefile (copy)      ├── Makefile (copy)
└── ...                  └── ...                  └── ...

Problems:
❌ Makefile duplicated across projects
❌ Bug fix requires updating every project
❌ Inconsistent behavior between projects
❌ Docker image selection per project
```

### After (New Architecture)

```
~/.wokenv/                                        
├── docker-compose.yml ← One for all projects    
├── Makefile           ← Shared logic            
└── bin/wokenv         ← Centralized CLI         

Project A/               Project B/               Project C/
├── wokenv.yml           ├── wokenv.yml           ├── wokenv.yml
├── .env                 ├── .env                 ├── .env
└── ...                  └── ...                  └── ...

Benefits:
✅ No code duplication
✅ Update once, all projects benefit
✅ Consistent behavior guaranteed
✅ Clear separation: global vs project config
```

## Testing Strategy

### Component Testing
1. **bin/wokenv**: Version checking, init wizard
2. **Makefile**: Parsing, docker-compose command construction
3. **docker-compose.yml**: Service startup, network creation

### Integration Testing
1. Create test project: `wokenv init`
2. Start environment: `wokenv start`
3. Verify services:
   - WordPress responds at :8888
   - Mailpit UI at :8025
   - phpMyAdmin at :9000
   - wp-env containers connected to network

### Upgrade Testing
1. Create project with Wokenv 1.0
2. Upgrade to Wokenv 1.1
3. Verify project still works
4. Test migration to 2.0 (when released)

## Future Considerations

### Planned Improvements
- [ ] JSON Schema for wokenv.yml (IDE autocomplete)
- [ ] Health checks for services
- [ ] Automated migration scripts
- [ ] Performance monitoring
- [ ] Multi-site support improvements

### Known Limitations
- Incompatible with Docker `userns-remap`
- Requires Docker socket access
- Limited to wp-env capabilities
- Single project per directory

## Contributing

When contributing to architecture:
1. Maintain centralized configuration approach
2. Preserve version compatibility system
3. Keep Makefile platform-agnostic
4. Document configuration precedence
5. Test across macOS, Linux, Windows

## References

- [@wordpress/env](https://github.com/WordPress/gutenberg/tree/trunk/packages/env)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Networking](https://docs.docker.com/network/)
- [GNU Make Manual](https://www.gnu.org/software/make/manual/)
