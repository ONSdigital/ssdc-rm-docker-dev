DOT := $(shell command -v dot 2> /dev/null)

# Set the container runtime based on architecture, default to docker for amd64 and podman for arm64
DOCKER ?= $(shell if [ "$$(uname -m)" = "arm64" ]; then echo podman; else echo docker; fi)

install:
	pipenv install --dev

up:
	$(DOCKER) network inspect ssdcrmdockerdev_default >/dev/null || $(DOCKER) network create ssdcrmdockerdev_default
	$(DOCKER) compose -f rm-dependencies.yml -f rm-services.yml up -d ${SERVICE} ;
	./setup_pubsub.sh

down:
	$(DOCKER) compose -f rm-dependencies.yml -f rm-services.yml down

pull:
	$(DOCKER) compose -f rm-dependencies.yml -f rm-services.yml pull ${SERVICE}

logs:
	$(DOCKER) compose -f rm-dependencies.yml -f rm-services.yml logs --follow ${SERVICE}

rebuild-java-healthcheck:
	$(MAKE) -C java_healthcheck rebuild-java-healthcheck

megalint:  ## Run the mega-linter.
	$(DOCKER) run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		oxsecurity/megalinter:v8

megalint-fix:  ## Run the mega-linter and attempt to auto fix any issues.
	$(DOCKER) run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		-e APPLY_FIXES=all \
		oxsecurity/megalinter:v8

clean_megalint: ## Clean the temporary files.
	rm -rf megalinter-reports

lint_check: clean_megalint megalint