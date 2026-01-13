# Wokenv - WordPress Development Environment Makefile
# https://github.com/wokenv/wokenv

# Wokenv directory
WOKENV_DIR := $(HOME)/.wokenv

# Self-reference for recursive calls
SELF := $(lastword $(MAKEFILE_LIST))

# Wokenv centralized Makefile (always points to ~/.wokenv/Makefile)
# Use this in Makefile.local to call centralized targets
WOKENV_MAKEFILE := $(WOKENV_DIR)/Makefile

# Project detection
PROJECT_DIR := $(shell pwd)
PROJECT_SLUG := $(shell basename $(PROJECT_DIR))

# Detect available YAML parsers
HAS_YQ := $(shell command -v yq 2>/dev/null)
HAS_PYTHON := $(shell command -v python3 2>/dev/null)
HAS_PYYAML := $(shell python3 -c "import yaml" 2>/dev/null && echo 1 || echo 0)

# Select YAML parser (priority: yq > python > grep/sed)
ifdef HAS_YQ
    YAML_PARSER := yq
else ifdef HAS_PYTHON
    ifeq ($(HAS_PYYAML),1)
        YAML_PARSER := python
    else
        YAML_PARSER := basic
    endif
else
    YAML_PARSER := basic
endif

# Parse wokenv.yml based on available parser
ifeq ($(YAML_PARSER),yq)
    # yq - Robust and fast
    WOKENV_NODE := $(shell yq eval '.image.node // 20' wokenv.yml 2>/dev/null || echo 20)
    WOKENV_VARIANT := $(shell yq eval '.image.variant // "alpine"' wokenv.yml 2>/dev/null || echo alpine)
    WOKENV_WPENV := $(shell yq eval '.image.wpenv // 10' wokenv.yml 2>/dev/null || echo 10)
    WOKENV_TAG := $(shell yq eval '.image.tag // ""' wokenv.yml 2>/dev/null)
    COMPOSE_PROJECT := $(shell yq eval '.project.slug // "$(PROJECT_SLUG)"' wokenv.yml 2>/dev/null || echo $(PROJECT_SLUG))
else ifeq ($(YAML_PARSER),python)
    # Python + PyYAML - Robust but slower
    WOKENV_NODE := $(shell python3 $(WOKENV_DIR)/lib/parse_yaml.py wokenv.yml image.node 20 2>/dev/null || echo 20)
    WOKENV_VARIANT := $(shell python3 $(WOKENV_DIR)/lib/parse_yaml.py wokenv.yml image.variant alpine 2>/dev/null || echo alpine)
    WOKENV_WPENV := $(shell python3 $(WOKENV_DIR)/lib/parse_yaml.py wokenv.yml image.wpenv 10 2>/dev/null || echo 10)
    WOKENV_TAG := $(shell python3 $(WOKENV_DIR)/lib/parse_yaml.py wokenv.yml image.tag "" 2>/dev/null)
    COMPOSE_PROJECT := $(shell python3 $(WOKENV_DIR)/lib/parse_yaml.py wokenv.yml project.slug "$(PROJECT_SLUG)" 2>/dev/null || echo $(PROJECT_SLUG))
else
    # grep/sed - Basic fallback (fragile but no dependencies)
    $(warning wokenv: Using basic YAML parser. Install yq or python3+pyyaml for robust parsing.)
    WOKENV_NODE := $(shell grep "^  node:" wokenv.yml 2>/dev/null | sed 's/[^0-9]*//g' | head -1 || echo 20)
    WOKENV_VARIANT := $(shell grep "^  variant:" wokenv.yml 2>/dev/null | sed 's/.*: *\([a-z]*\).*/\1/' | head -1 || echo alpine)
    WOKENV_WPENV := $(shell grep "^  wpenv:" wokenv.yml 2>/dev/null | sed 's/[^0-9]*//g' | head -1 || echo 10)
    WOKENV_TAG := $(shell grep "^  tag:" wokenv.yml 2>/dev/null | sed 's/.*tag: *\(.*\)/\1/' | sed 's/^[# ]*//' | head -1)
    COMPOSE_PROJECT := $(shell grep "^  slug:" wokenv.yml 2>/dev/null | sed 's/.*slug: *\(.*\)/\1/' | sed 's/^[# ]*//' | head -1 || echo $(PROJECT_SLUG))
endif

# Determine final image tag
ifeq ($(WOKENV_TAG),)
    WOKENV_IMAGE := frugan/wokenv:node$(WOKENV_NODE)-$(WOKENV_VARIANT)-wpenv$(WOKENV_WPENV)
else
    WOKENV_IMAGE := $(WOKENV_TAG)
endif

# Load .env if it exists (overrides wokenv.yml for runtime values)
-include .env

# Export variables for docker-compose
export PROJECT_DIR
export WOKENV_IMAGE
export COMPOSE_PROJECT_NAME := $(COMPOSE_PROJECT)
export USER_ID ?= $(shell id -u)
export GROUP_ID ?= $(shell id -g)

# Detect Docker Compose command (V2 integrated or V1 standalone)
# Use ?= to allow override from parent make process
COMPOSE_CMD ?= $(shell docker compose version 2>/dev/null && echo "docker compose" || command -v docker-compose 2>/dev/null && echo "docker-compose" || echo "")

ifeq ($(COMPOSE_CMD),)
    $(error Docker Compose not found. Install Docker with Compose V2 or standalone docker-compose)
endif

# Docker Compose with centralized config
DOCKER_COMPOSE := $(COMPOSE_CMD) -f $(WOKENV_DIR)/docker-compose.yml

# Include override if it exists
ifneq (,$(wildcard docker-compose.override.yml))
    DOCKER_COMPOSE += -f docker-compose.override.yml
endif

# wp-env container naming patterns
WP_CONTAINER_PATTERN := $(COMPOSE_PROJECT)-wordpress-1
MYSQL_CONTAINER_PATTERN := $(COMPOSE_PROJECT)-mysql-1
TESTS_CONTAINER_PATTERN := $(COMPOSE_PROJECT)-tests-wordpress-1
CLI_CONTAINER_PATTERN := $(COMPOSE_PROJECT)-cli-1

# Network name
NETWORK_NAME := $(COMPOSE_PROJECT)-network

.PHONY: help install start stop restart destroy cli node-install composer-install composer-update test shell mysql reset-db fix-perms clean info connect-network

help: ## Show this help message
	@echo "Wokenv - WordPress Development Environment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Configuration:"
	@echo "  Image:   $(WOKENV_IMAGE)"
	@echo "  Project: $(COMPOSE_PROJECT)"
	@echo "  User:    $(USER_ID):$(GROUP_ID)"
	@echo "  Parser:  $(YAML_PARSER)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install npm and composer dependencies (optional, see docs)
	@echo "Installing dependencies..."
	@$(MAKE) -f $(SELF) COMPOSE_CMD="$(COMPOSE_CMD)" WOKENV_DIR="$(WOKENV_DIR)" node-install
	@if [ -f "composer.json" ] && [ ! -d "vendor" ]; then \
		echo "Installing composer dependencies..."; \
		$(MAKE) -f $(SELF) COMPOSE_CMD="$(COMPOSE_CMD)" WOKENV_DIR="$(WOKENV_DIR)" composer-install; \
	fi

start: ## Start WordPress environment
	@echo "Starting Docker Compose services..."
	@mkdir -p $(HOME)/.wp-env
	@$(DOCKER_COMPOSE) up -d
	@echo "Starting wp-env..."
	@$(DOCKER_COMPOSE) exec wokenv npm run env:start
	@echo "Connecting wp-env containers to shared network..."
	@$(MAKE) -f $(SELF) connect-network
	@$(MAKE) -f $(SELF) fix-perms
	@echo ""
	@echo "✓ WordPress started!"
	@echo ""
	@echo "WordPress:    http://localhost:8888"
	@echo "Admin:        http://localhost:8888/wp-admin (admin/password)"
	@echo "Tests:        http://localhost:8889"
	@echo ""
	@echo "Additional services:"
	@echo "Mailpit:      http://localhost:$(MAILPIT_WEB_PORT:-8025)"
	@echo "phpMyAdmin:   http://localhost:$(PHPMYADMIN_PORT:-9000) (root/password)"
	@echo ""

stop: ## Stop WordPress environment
	@echo "Stopping wp-env..."
	@$(DOCKER_COMPOSE) exec wokenv npm run env:stop 2>/dev/null || true
	@echo "Stopping Docker Compose services..."
	@$(DOCKER_COMPOSE) down

restart: ## Restart WordPress environment
	@$(MAKE) -f $(SELF) COMPOSE_CMD="$(COMPOSE_CMD)" WOKENV_DIR="$(WOKENV_DIR)" stop
	@$(MAKE) -f $(SELF) COMPOSE_CMD="$(COMPOSE_CMD)" WOKENV_DIR="$(WOKENV_DIR)" start

destroy: ## Destroy WordPress environment (delete all data)
	@echo "⚠️  This will permanently delete all WordPress data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DOCKER_COMPOSE) exec wokenv npm run env:destroy 2>/dev/null || true; \
		$(DOCKER_COMPOSE) down -v; \
		echo "✓ Environment destroyed"; \
	fi

cli: ## Open WP-CLI in WordPress container
	@$(DOCKER_COMPOSE) exec wokenv npm run env:cli $(filter-out $@,$(MAKECMDGOALS))

node-install: ## Install npm dependencies
	@if [ ! -d "node_modules" ]; then \
		$(DOCKER_COMPOSE) run --rm wokenv npm install; \
		echo "✓ npm dependencies installed"; \
	else \
		echo "✓ node_modules already exists"; \
	fi

composer-install: ## Run composer install
	@$(DOCKER_COMPOSE) exec wokenv npm run env:composer install

composer-update: ## Run composer update
	@$(DOCKER_COMPOSE) exec wokenv npm run env:composer update

test: ## Run PHPUnit tests
	@$(DOCKER_COMPOSE) exec wokenv npm run env:test

shell: ## Open shell in WordPress container
	@$(DOCKER_COMPOSE) exec wokenv npm run env:cli bash

mysql: ## Access MySQL database
	@echo "Connecting to MySQL..."
	@echo "Database: wordpress | User: root | Password: password"
	@$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db cli

reset-db: ## Reset database (WARNING: deletes all data)
	@echo "⚠️  WARNING: This will permanently delete all posts, pages, media, etc."
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DOCKER_COMPOSE) exec wokenv npm run env:cli -- wp db reset --yes; \
	fi

connect-network: ## Connect wp-env containers to docker-compose network
	@WP_CONTAINER=$$(docker ps -q --filter "name=$(WP_CONTAINER_PATTERN)" 2>/dev/null | head -1); \
	MYSQL_CONTAINER=$$(docker ps -q --filter "name=$(MYSQL_CONTAINER_PATTERN)" 2>/dev/null | head -1); \
	TESTS_CONTAINER=$$(docker ps -q --filter "name=$(TESTS_CONTAINER_PATTERN)" 2>/dev/null | head -1); \
	if [ -n "$$WP_CONTAINER" ]; then \
		docker network connect $(NETWORK_NAME) $$WP_CONTAINER 2>/dev/null && echo "  ✓ Connected WordPress container" || true; \
	fi; \
	if [ -n "$$MYSQL_CONTAINER" ]; then \
		docker network connect $(NETWORK_NAME) $$MYSQL_CONTAINER 2>/dev/null && echo "  ✓ Connected MySQL container" || true; \
	fi; \
	if [ -n "$$TESTS_CONTAINER" ]; then \
		docker network connect $(NETWORK_NAME) $$TESTS_CONTAINER 2>/dev/null && echo "  ✓ Connected Tests container" || true; \
	fi

fix-perms: ## Fix WordPress file permissions
	@echo "Fixing WordPress permissions..."
	@WP_CONTAINER=$$(docker ps -q --filter "name=$(WP_CONTAINER_PATTERN)" 2>/dev/null | head -1); \
	TESTS_CONTAINER=$$(docker ps -q --filter "name=$(TESTS_CONTAINER_PATTERN)" 2>/dev/null | head -1); \
	if [ -n "$$WP_CONTAINER" ]; then \
		docker exec $$WP_CONTAINER chown -R 1000:1000 /var/www/html 2>/dev/null || true; \
	fi; \
	if [ -n "$$TESTS_CONTAINER" ]; then \
		docker exec $$TESTS_CONTAINER chown -R 1000:1000 /var/www/html 2>/dev/null || true; \
	fi; \
	echo "✓ Permissions fixed"

clean: ## Clean npm and composer dependencies
	rm -rf node_modules package-lock.json vendor composer.lock

info: ## Show environment info
	@echo "═══════════════════════════════════════════════════"
	@echo "  Wokenv - WordPress Development Environment"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Project: $(COMPOSE_PROJECT)"
	@echo ""
	@echo "Configuration:"
	@echo "  • Docker Image: $(WOKENV_IMAGE)"
	@echo "  • User Mapping: $(USER_ID):$(GROUP_ID)"
	@echo "  • YAML Parser:  $(YAML_PARSER)"
	@if [ -f "wokenv.yml" ]; then \
		echo "  • Config File:  wokenv.yml (present)"; \
	else \
		echo "  • Config File:  wokenv.yml (not found, using defaults)"; \
	fi
	@echo ""
	@echo "WordPress URLs:"
	@echo "  • Site:  http://localhost:8888"
	@echo "  • Admin: http://localhost:8888/wp-admin"
	@echo "  • User:  admin / password"
	@echo "  • Tests: http://localhost:8889"
	@echo ""
	@echo "Additional Services:"
	@echo "  • Mailpit (email):     http://localhost:$(MAILPIT_WEB_PORT:-8025)"
	@echo "  • phpMyAdmin (db):     http://localhost:$(PHPMYADMIN_PORT:-9000)"
	@echo ""
	@echo "Database Connection:"
	@echo "  • Name:     wordpress"
	@echo "  • User:     root"
	@echo "  • Password: password"
	@echo "  • Host:     127.0.0.1"
	@echo "  • Port:     (dynamic, see 'docker ps')"
	@echo ""
	@echo "Parser Status:"
	@if [ "$(YAML_PARSER)" = "yq" ]; then \
		echo "  • yq:          ✓ installed (robust parsing)"; \
	else \
		echo "  • yq:          ✗ not found"; \
	fi
	@if [ -n "$(HAS_PYTHON)" ]; then \
		if [ "$(HAS_PYYAML)" = "1" ]; then \
			echo "  • python+yaml: ✓ installed"; \
		else \
			echo "  • python+yaml: python found, PyYAML missing"; \
		fi; \
	else \
		echo "  • python+yaml: python not found"; \
	fi
	@if [ "$(YAML_PARSER)" = "basic" ]; then \
		echo ""; \
		echo "  ⚠️  Using basic parser. For robust YAML parsing:"; \
		echo "     wokenv self-install-deps"; \
	fi
	@echo ""
	@echo "Common Commands:"
	@echo "  • make start            - Start environment"
	@echo "  • make stop             - Stop environment"
	@echo "  • make install          - Install npm and composer dependencies"
	@echo "  • make mysql            - Access database"
	@echo "  • make cli              - Run WP-CLI commands"
	@echo "  • make test             - Run tests"
	@echo ""
	@echo "═══════════════════════════════════════════════════"

# Include local project customizations if they exist
-include Makefile.local

# Allow passing arguments to targets
%:
	@:
