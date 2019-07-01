#!/usr/bin/env bash
if [ ${#} -ne 2 ]; then
  echo "Usage: csv2useradd <users.csv> <home_skeleton>"
  exit 1
fi

pushd "$2"; ln -s /shared; popd

# first row is heading
tail -n+2 "$1" | while read user_pass; do
  user=$(echo $user_pass | cut -d, -f1)
  pass=$(echo $user_pass | cut -d, -f2)
  useradd -g conjuring -m -k "$2" -p $(echo "$pass" | openssl passwd -1 -stdin) "$user"
done
