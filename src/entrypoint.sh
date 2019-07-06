#!/bin/bash
# Copy built user directories to host-mounted custom/home:/home before starting
# JupyterHub.
# NB: As with a host-based system, due to security/access permissions,
# it will likely will need sudo/root to access from the host.

#chmod 755 /home
#chown root:root /home
for d in $(ls -d /opt/home-init/*); do
  cp -a $d /home/
done

jupyterhub
