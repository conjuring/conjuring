REPO=conjuring
DCC=docker compose

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
test:
	$(MAKE) up
	$(DCC) exec -T conjuring bash -c "/conda.sh env list"
	$(DCC) exec -T conjuring bash -c "ls -la /home/"
	$(MAKE) down
bash:
	$(DCC) exec $(REPO) bash
prune:
	docker system prune
