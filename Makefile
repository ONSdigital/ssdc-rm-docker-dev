DOT := $(shell command -v dot 2> /dev/null)

rm-up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f dev.yml -f rm-services.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh

rh-up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f rh-dev.yml -f rh-services.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh

rmrh-up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker compose -f dev.yml -f rm-services.yml -f rh-dev.yml -f rh-services.yml up -d ${SERVICE} ;
	pipenv install --dev
	./setup_pubsub.sh
	
rm-down:
	docker compose -f dev.yml -f rm-services.yml down

rh-down:
	docker compose -f rh-dev.yml -f rh-services.yml down

rmrh-down:
	docker compose -f dev.yml -f rm-services.yml -f rh-dev.yml -f rh-services.yml down

rm-pull:
	docker compose -f dev.yml -f rm-services.yml pull ${SERVICE}

rh-pull:
	docker compose -f rh-dev.yml -f rh-services.yml pull ${SERVICE}

rmrh-pull:
	docker compose -f dev.yml -f rm-services.yml -f rh-dev.yml -f rh-services.yml pull ${SERVICE}

rm-logs:
	docker compose -f dev.yml -f rm-services.yml logs --follow ${SERVICE}

rh-logs:
	docker compose -f rh-dev.yml -f rh-services.yml logs --follow ${SERVICE}

rmrh-logs:
	docker compose -f dev.yml -f rm-services.yml -f rh-dev.yml -f rh-services.yml logs --follow ${SERVICE}

clean:
	rm -f plantuml.jar; rm -f diagrams/*.svg
