#!/bin/bash
# Copy built user directories to host-mounted custom/home:/home before starting
# JupyterHub.
# NB: As with a host-based system, due to security/access permissions,
# it will likely will need sudo/root to access from the host.

# create users and populate home directories if necessary
/opt/csv2useradd.sh /opt/users.csv /opt/home_default

# ensure correct permissions
#chmod 755 /home
#chown root:root /home
pushd /home
for d in $(ls -d *); do
  if [ -d /home/$d ]; then
    # necessary since UID could have been altered by modifying users.csv
    id $d && chown -R $d:conjuring /home/$d
  fi
done
popd

jupyterhub
