REPO=conjuring
DCC=docker-compose

default: buildup bash down
up:
	$(DCC) up -d $(REPO)
buildup:
	$(DCC) up --build -d $(REPO)
down:
	$(DCC) down
build:
	$(DCC) build --pull base
	$(DCC) build
bash:
	$(DCC) exec $(REPO) bash
