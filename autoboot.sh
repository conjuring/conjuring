#!/usr/bin/env bash
show_help(){
echo 'Usage:
  '$0' [options] [<workdir>]

A script which:
- starts an ssh server
- connects to the specified --build-net
- (re)builds a conjuring docker image based on the given <workdir> configuration
- starts a conjuring container
- connects to the specified --serve-net
- continuously monitors --monitor-dir for additional configuration

Flags:
  -h, --help
Options:
  -s, --serve-net  (default: Hotspot)
  -b, --build-net  (e.g. eduroam)
  -l, --log-file  (default: conjuring.log)
  -m, --monitor-dir  (default: /media/*/*/conjuring/custom)
Arguments:
  workdir (default: current)
'
}

set -o errexit -o pipefail -o noclobber -o nounset
OPTIND=1  # reset getopts

# defaults
## options
WIFI_SERVE_NET=Hotspot
WIFI_BUILD_NET=""  # TODO: special value for auto?
LOG_FILE=conjuring.log
CUSTOM_DIR='/media/*/*/conjuring/custom'
## arguments
WORKDIR="${PWD}"
## internal
CUSTOM_ROOT_FILES="docker-compose.override.yml"

OPTIONS=hs:b:l:m:
LONGOPTS=help,serve-net:,build-net:,log-file:,monitor-dir:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
[[ ${PIPESTATUS[0]} -ne 0 ]] && exit 2
eval set -- "$PARSED"

while true; do
  case "$1" in
  -h|--help)
    show_help
    exit 0
    ;;
  -s|--serve-net)
    WIFI_SERVE_NET="$2"
    shift 2
    ;;
  -b|--build-net)
    WIFI_BUILD_NET="$2"
    shift 2
    ;;
  -l|--log-file)
    LOG_FILE="$2"
    shift 2
    ;;
  -m|--monitor-dir)
    CUSTOM_DIR="$2"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Programming error"
    exit 3
    ;;
  esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

WORKDIR="${1:-$WORKDIR}"

# end options

log(){
  level=$1
  msg="${@:2}"
  case $level in
  I|i|[Ii][Nn][Ff][Oo]*)
    echo "I:$(date -Is):autoboot:$msg"
    ;;
  E|e|[Ee][Rr][Rr]*)
    echo "E:$(date -Is):autoboot:$msg" 1>&2
    ;;
  D|d|[Dd][Ee][Bb]*)
    ;;
  *)
    echo "I:$(date -Is):autoboot:$@"
    ;;
  esac
}
rm -f $LOG_FILE
echo -n '' > $LOG_FILE

log debug Ensuring sshserver >> $LOG_FILE 2>&1
sudo service ssh start

netup(){
  if [ -n "$1" ]; then
    log info Starting/connecting to network: "'$1'" >> $LOG_FILE 2>&1
    nmcli connection up "$1" >> $LOG_FILE 2>&1
  fi
}
# netup "$WIFI_BUILD_NET"

# docker container with mounted shared folder(s)
dcc(){
  pushd $WORKDIR
  log info docker-compose $@
  docker-compose $@
  popd
}
dccup(){
  netup "$WIFI_BUILD_NET"
  dcc build --pull base
  dcc up --build --no-start
  netup "$WIFI_SERVE_NET"
  dcc up -d
}

supports_perms(){
  type=$(df -T "$1" | awk 'NR==2{print $2}')
  case $type in
  btrfs|ext*|?fs)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
  return 2
}

usb_monitor(){
  log info Monitor for a USB storage device containing additional config
  usb_found=""
  while [ true ]; do
    if [ -n "$usb_found" ]; then
      ls $CUSTOM_DIR &>/dev/null || usb_found=''
      [ -z "$usb_found" ] && log info Unplugged
    else
      ls $CUSTOM_DIR &>/dev/null && usb_found="$CUSTOM_DIR" && (
        log info Copying found $CUSTOM_DIR
        cp -Ru $CUSTOM_DIR "$WORKDIR"
        # rm -rf "$WORKDIR"/custom/home_backup  # TODO: avoid this copy
        log info Pull custom root files from media
        for f in $CUSTOM_ROOT_FILES; do
          [ -f $CUSTOM_DIR/../$f ] && \
         cp -u $CUSTOM_DIR/../$f "$WORKDIR"/
        done
        if [ -d $CUSTOM_DIR/home_backup ]; then
         log info Push homes to media
         if supports_perms $CUSTOM_DIR/home_backup; then
           log info In-place
           sudo rsync -au --delete "$WORKDIR"/custom/home/ $CUSTOM_DIR/home_backup
         else
           log info tar
           pushd "$WORKDIR"/custom/home
           if [ -f $CUSTOM_DIR/home_backup/home.tar ]; then
             log debug Updating tar
             sudo tar -upv --exclude-backups -f $CUSTOM_DIR/home_backup/home.tar *
           else
             log debug Creating tar
             sudo tar -cpv --exclude-backups -f $CUSTOM_DIR/home_backup/home.tar *
           fi
           popd
         fi
        fi

        # TODO: overwrite?
        # TODO: backup?
        # TODO: copy missing back? cp -au "$WORKDIR"/custom "$CUSTOM_DIR"/..
        # TODO: check for multiple USB?

        dcc down
        # TODO: maybe don't bring container down if updateable live?
        dccup
      )
    fi
    sleep 1
  done
}

log info Build and run container >> $LOG_FILE 2>&1
dccup >> $LOG_FILE 2>&1

usb_monitor >> $LOG_FILE 2>&1 &
wait
