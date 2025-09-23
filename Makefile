DOT := $(shell command -v dot 2> /dev/null)

install:
	pipenv install --dev

up:
	podman network inspect ssdcrmdockerdev_default >/dev/null || podman network create ssdcrmdockerdev_default
	podman compose -f rm-dependencies.yml -f rm-services.yml up -d ${SERVICE} ;
	./setup_pubsub.sh

down:
	podman compose -f rm-dependencies.yml -f rm-services.yml down

pull:
	podman compose -f rm-dependencies.yml -f rm-services.yml pull ${SERVICE}

logs:
	podman compose -f rm-dependencies.yml -f rm-services.yml logs --follow ${SERVICE}

rebuild-java-healthcheck:
	$(MAKE) -C java_healthcheck rebuild-java-healthcheck

megalint:  ## Run the mega-linter.
	podman run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		oxsecurity/megalinter:v8

megalint-fix:  ## Run the mega-linter and attempt to auto fix any issues.
	podman run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		-e APPLY_FIXES=all \
		oxsecurity/megalinter:v8

clean_megalint: ## Clean the temporary files.
	rm -rf megalinter-reports

lint_check: clean_megalint megalint