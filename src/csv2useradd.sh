#!/usr/bin/env bash
if [ ${#} -ne 2 ]; then
  echo "Usage: csv2useradd <users.csv> <home_skeleton>"
  exit 1
fi

ADMINS=""

# first row is heading
awk -F, 'NR>1{print $1" "$2" "$3}' "$1" | while read user pass admin; do
  useradd -g conjuring -m -K UID_MIN=2000 -k "$2" -p $(echo "$pass" | openssl passwd -1 -stdin) "$user"
  case "$admin" in
  [1YyTt]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee])
    echo TODO: useradd -G sudoers "$user"
    ADMINS="${ADMINS:+${ADMINS}, }'$user'"
    # TODO (minor): remove (subshell-induced duplication)
    echo "c.Authenticator.admin_users = {$ADMINS}" >> jupyterhub_config.py
    ;;
  esac
  pushd /home/"$user"
    [ -e shared ] || ln -s /shared
  popd
done

if [ -n "$ADMINS" ]; then
  echo "c.Authenticator.admin_users = {$ADMINS}" >> jupyterhub_config.py
fi
