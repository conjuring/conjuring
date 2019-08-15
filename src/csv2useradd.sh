#!/usr/bin/env bash
if [ ${#} -ne 2 ]; then
  echo "Usage: csv2useradd <users.csv> <home_skeleton>"
  exit 1
fi

# first row is heading
awk -F, 'NR>1{print $1" "$2}' "$1" | while read user pass; do
  useradd -g conjuring -m -K UID_MIN=2000 -k "$2" -p $(echo "$pass" | openssl passwd -1 -stdin) "$user"
  pushd /home/"$user"
    [ -e shared ] || ln -s /shared
  popd
done
