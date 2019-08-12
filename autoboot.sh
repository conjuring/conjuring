#!/usr/bin/env bash

# Options
WORKDIR=${PWD}
CUSTOM_DIR='/media/*/*/conjuring/custom'
CUSTOM_ROOT_FILES="docker-compose.override.yml"

# auto-start WiFi hotspot
# TODO

# sshserver
sudo service ssh start

# docker container with mounted shared folder(s)
dcc(){
  pushd $WORKDIR
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

# monitor for a USB storage device containing additional config
usb_monitor(){
  while [ true ]; do
    if [ -n "$usb_found" ]; then
      ls $CUSTOM_DIR &>/dev/null || usb_found=''
      [ -z "$usb_found" ] && echo unplugged
    else
      ls $CUSTOM_DIR 2>/dev/null && usb_found="$CUSTOM_DIR" && (
        echo copying found $CUSTOM_DIR
        cp -Ru $CUSTOM_DIR "$WORKDIR"
        # pull custom root files from media
        for f in $CUSTOM_ROOT_FILES; do
          [ -f $CUSTOM_DIR/../$f ] && \
         cp -u $CUSTOM_DIR/../$f "$WORKDIR"/../
        done
        # push homes to media
        if [ -d $CUSTOM_DIR/home_backup ]; then
         if supports_perms $CUSTOM_DIR/home_backup; then
           sudo rsync -au --delete "$WORKDIR"/custom/home/ $CUSTOM_DIR/home_backup
         else
           pushd "$WORKDIR"/custom/home
           sudo tar -upv --exclude-backups -f $CUSTOM_DIR/home_backup/home.tar *
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

# build and run container
dccup > $WORKDIR/conjuring.log

usb_monitor >> $WORKDIR/conjuring.log 2>&1 &
wait
