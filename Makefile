DOT := $(shell command -v dot 2> /dev/null)

rm-up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f rm-dependencies.yml -f rm-services.yml -f common-dependencies.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh

rh-up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh

up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f rm-dependencies.yml -f rm-services.yml -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh
	
rm-down:
	docker compose -f rm-dependencies.yml -f rm-services.yml down

rh-down:
	docker compose -f rh-dependencies.yml -f rh-services.yml down

common-down:
	 docker compose -f common-dependencies.yml down

down:
	docker compose -f rm-dependencies.yml -f rm-services.yml -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml down

rm-pull:
	docker compose -f rm-dependencies.yml -f rm-services.yml -f common-dependencies.yml pull ${SERVICE}

rh-pull:
	docker compose -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml pull ${SERVICE}

pull:
	docker compose -f rm-dependencies.yml -f rm-services.yml -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml pull ${SERVICE}

rm-logs:
	docker compose -f rm-dependencies.yml -f rm-services.yml -f common-dependencies.yml logs --follow ${SERVICE}

rh-logs:
	docker compose -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml logs --follow ${SERVICE}

logs:
	docker compose -f rm-dependencies.yml -f rm-services.yml -f rh-dependencies.yml -f rh-services.yml -f common-dependencies.yml logs --follow ${SERVICE}

clean:
	rm -f plantuml.jar; rm -f diagrams/*.svg
