DOT := $(shell command -v dot 2> /dev/null)

install:
	pipenv install --dev

up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f rm-dependencies.yml -f rm-services.yml up -d ${SERVICE} ;
	./setup_pubsub.sh

down:
	docker compose -f rm-dependencies.yml -f rm-services.yml down

pull:
	docker compose -f rm-dependencies.yml -f rm-services.yml pull ${SERVICE}

logs:
	docker compose -f rm-dependencies.yml -f rm-services.yml logs --follow ${SERVICE}

rebuild-java-healthcheck:
	$(MAKE) -C java_healthcheck rebuild-java-healthcheck

megalint:  ## Run the mega-linter.
	docker run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		oxsecurity/megalinter:v8

megalint-fix:  ## Run the mega-linter and attempt to auto fix any issues.
	docker run --platform linux/amd64 --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:rw \
		-v $(shell pwd):/tmp/lint:rw \
		-e APPLY_FIXES=all \
		oxsecurity/megalinter:v8

clean_megalint: ## Clean the temporary files.
	rm -rf megalinter-reports

lint_check: clean_megalint megalint