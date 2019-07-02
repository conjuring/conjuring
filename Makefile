REPO=conjuring
DCC=docker-compose

default: build up bash down
up:
	$(DCC) up -d
down:
	$(DCC) down
build:
	$(DCC) build --pull base
	$(DCC) build core
	$(DCC) build $(REPO)
bash:
	$(DCC) exec $(REPO) bash
