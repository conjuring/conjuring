#!/bin/bash
# Copy built user directories to host-mounted custom/home:/home before starting
# JupyterHub.
# NB: As with a host-based system, due to security/access permissions,
# it will likely will need sudo/root to access from the host.

#chmod 755 /home
#chown root:root /home
pushd /opt/home-init
for d in $(ls -d *); do
  if [ -d $d ]; then
    # copy if does not already exist (TODO: one-way sync?)
    [ -d /home/$d ] || cp -a $d /home/
    # ensure correct user permissions
    # since UID could have been altered by modifying users.csv
    id $d && chown -R $d:conjuring /home/$d
  fi
done
popd

jupyterhub
