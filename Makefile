DOT := $(shell command -v dot 2> /dev/null)

install:
	pipenv install --dev

check:
	pipenv check

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
