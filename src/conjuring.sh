#!/usr/bin/env bash
help(){
cat << EOF
Conjuring install helper.

Available commands:
- $0 up
- $0 config
- $0 uninstall

Steps to use:
- install \`git\`
  + \`sudo apt-get install git curl\` (linux)
  + \`brew install git curl\` (mac)
  + https://git-scm.com/download (win, includes \`git-bash\` and \`curl\` etc.)
- (win) open \`git-bash\` terminal
- \`curl -o conjuring https://raw.githubusercontent.com/conjuring/conjuring/master/src/conjuring.sh\`
  + or e.g. \`curl -o ~/.local/bin/conjuring https://conjuring.github.io/conjuring.sh\`
- \`./conjuring\`
EOF
}
set -e

CWD="${PWD}"

config(){
# TODO: prevent irrelevant git-confog optiona
git config --file conjuring.ini "$@"
}

up(){
echo "Ensuring conjuring is up-to-date in ~/.conjuring"
[ -d ~/.conjuring ] || git clone https://github.com/conjuring/conjuring ~/.conjuring
pushd ~/.conjuring
git reset --hard
git pull
files="$(ls -xd */ *.yml Dockerfile)"  # slim
#files=""  # full (incl README.md, Makefile, autoboot.sh, etc)
echo "Installing conjuring ($files) in $CWD"
echo -n "Overwrite all, overwrite older, keep existing, or quit [a/o/E/q]? "
read overwrite
case "$overwrite" in
  [aA])
    git archive --format=tar HEAD $files | (cd "$CWD" && tar -x -f - )
    ;;
  [oO])
    git archive --format=tar HEAD $files | (cd "$CWD" && tar -x -f - --keep-newer-files)
    ;;
  [eE]|"")
    git archive --format=tar HEAD $files | (cd "$CWD" && tar -x -f - --skip-old-files)
    ;;
  [qQ])
    exit 0
    ;;
  *)
    echo "Unknown option; aborting"
    exit 1
    ;;
esac
popd

docker-compose up --build -d
}

case "$1" in
  up|"")
    up "${@:2}"
    ;;
  uninstall)
    rm -rf ~/.conjuring
    ;;
  config)
    config "${@:2}"
    ;;
  *)
    help >&2
    ;;
esac
