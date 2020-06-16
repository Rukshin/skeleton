ENV := dev
DOCKER_CONTAINER := skeleton-fpm
USER := www-data
SERVICES :=

# Detect docker executable and when called inside container
DOCKER :=
DOCKER_OPTIONS = --user $(USER)
DOCKER_EXEC := "$(shell which docker docker.exe | head -n1)"
ifneq ($(DOCKER_EXEC),"")
	DOCKER = $(DOCKER_EXEC) exec $(DOCKER_OPTIONS) $(DOCKER_CONTAINER)
endif

CONSOLE = bin/console --no-interaction --env $(ENV)

.DEFAULT_GOAL = help
.SUFFIXES:
ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help: ## Show command list
	echo You can use the following commands:
	# Parses current makefile looking for targets
	# Comments after the command are used as description
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN { FS = ":.*?## " }; { printf " - \033[36m%s:\033[0m %s\n", $$1, $$2 }'
	echo

.PHONY: build
build: .docker-compose ## Build application images
	docker-compose build $(SERVICES)

.PHONY: composer
composer: COMMAND = install
composer: ## Run composer
	$(DOCKER) php -dmemory_limit=-1 /usr/bin/composer $(COMMAND)

.PHONY: down
down: ## Stop application
	docker-compose stop

.PHONY: install
install: .docker-compose build up composer ## First time install

.PHONY: run-tests
run-tests: .ensure-up xdebug-status ## Execute tests with XDebug disabled
	$(DOCKER) bin/simple-phpunit --testdox

.PHONY: sh
sh: SHELL_COMMAND = bash -l
sh: DOCKER_OPTIONS += -it
sh: .run-command ## Shell session

.PHONY: sh-root
sh-root: SHELL_COMMAND = bash -l
sh-root: DOCKER_OPTIONS += -it
sh-root: .run-command-as-root ## Shell session as ROOT

.PHONY: .run-command
.run-command: .ensure-up
	$(DOCKER) $(SHELL_COMMAND)

.PHONY: .run-command-as-root
.run-command-as-root: USER = root
.run-command-as-root: .run-command

.PHONY: xdebug-on
xdebug-on: SHELL_COMMAND = phpenmod xdebug
xdebug-on: .run-command-as-root ## Activate XDebug
	$(MAKE) restart-fpm
	$(MAKE) xdebug-status

.PHONY: xdebug-off
xdebug-off: SHELL_COMMAND = phpdismod xdebug
xdebug-off: .run-command-as-root ## Deactivate XDebug
	$(MAKE) restart-fpm
	$(MAKE) xdebug-status

.PHONY: xdebug-status
xdebug-status: ## Show XDebug status
	$(MAKE) .run-command SHELL_COMMAND='php -m' | fgrep -iq xdebug && echo PHP XDebug is enabled || echo PHP XDebug is disabled

.PHONY: restart-fpm
restart-fpm: SHELL_COMMAND = /etc/init.d/php-fpm restart > /dev/null
restart-fpm: .run-command-as-root ## Restart PHP-FPM

.PHONY: status
status: ## Check application status
	docker-compose ps

.PHONY: up
up: docker-compose.yml ## Start application
	docker-compose up -d

.PHONY: .ensure-up
.ensure-up:
ifeq ("$(shell docker ps -q -f status=running -f name=$(DOCKER_CONTAINER))", "")
	make up
endif

.docker-compose: docker-compose.yml

docker-compose.yml: etc/docker/dev/docker-compose.yml.dist
	cp "$^" "$@"
