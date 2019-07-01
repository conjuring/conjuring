REPO=conjuring
DCC=docker-compose

default: build up bash down
up:
	$(DCC) up -d $(REPO)
down:
	$(DCC) down
build:
	$(DCC) build --pull $(REPO)
bash:
	$(DCC) exec $(REPO) bash

cert:
	#openssl req -new > my.csr
	echo -ne "GB\nLondon\n\n\n\nCasper da Costa-Luis\ncasper.dcl@ieee.org\n\n\n" | openssl req -new -key privkey.pem > my.csr
	openssl rsa -in privkey.pem -out srv/my.key
	openssl x509 -in my.csr -out srv/my.cert -req -signkey srv/my.key -days 999
	chmod 600 srv/my.key
	chmod 664 srv/my.cert

lol:
	openssl req -x509 -out localhost.crt -keyout localhost.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=localhost' -extensions EXT -config <(printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
	openssl req -x509 -out localhost.crt -keyout localhost.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=localhost' -extensions EXT -config <(printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
