REPO=conjuring
DCC=docker-compose

default: build up bash down
up:
	$(DCC) up -d $(REPO)
down:
	$(DCC) down
build:
	$(DCC) build --pull base
	$(DCC) build
bash:
	$(DCC) exec $(REPO) bash
