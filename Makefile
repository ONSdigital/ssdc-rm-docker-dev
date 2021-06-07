DOT := $(shell command -v dot 2> /dev/null)

up:
	docker network inspect ssdcrmdockerdev_default >/dev/null || docker network create ssdcrmdockerdev_default
	docker-compose -f dev.yml -f rm-services.yml up -d ${SERVICE} ;
	pipenv install --dev
	pipenv run python setup_database.py
	./setup_pubsub.sh
	
down:
	docker-compose -f dev.yml -f rm-services.yml down

pull:
	docker-compose -f dev.yml -f rm-services.yml pull ${SERVICE}

logs:
	docker-compose -f dev.yml -f rm-services.yml logs --follow ${SERVICE}

clean:
	rm -f plantuml.jar; rm -f diagrams/*.svg
