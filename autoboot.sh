#!/usr/bin/env bash

# Options
HOTSPOT_NM='Hotspot'
WORKDIR="${PWD}"
LOG_FILE="$WORKDIR"/conjuring.log
CUSTOM_DIR='/media/*/*/conjuring/custom'
CUSTOM_ROOT_FILES="docker-compose.override.yml"

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
echo -n '' > $LOG_FILE

log info Starting $'Wi-Fi: \"'"$HOTSPOT_NM"$'\"' >> $LOG_FILE 2>&1
nmcli connection up Hotspot >> $LOG_FILE 2>&1

log debug Ensuring sshserver >> $LOG_FILE 2>&1
sudo service ssh start

# docker container with mounted shared folder(s)
dcc(){
  pushd $WORKDIR
  log info docker-compose $@
  docker-compose $@
  popd
}
dccup(){
  dcc build --pull base
  dcc up --build -d
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
