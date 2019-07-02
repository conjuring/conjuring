#!/usr/bin/env bash

# Options
WORKDIR=${PWD}
CUSTOM_DIR='/media/*/conjuring/custom'

# auto-start WiFi hotspot
# TODO

# sshserver
sudo service ssh stop

# monitor for a USB storage device containing additional config
usb_monitor(){
  while [ true ]; do
    if [ -n "$usb_found" ]; then
      # unplugged
      ls "$CUSTOM_DIR" 2>/dev/null || usb_found=''
    else
      # found dir
      ls "$CUSTOM_DIR" 2>/dev/null && usb_found="(ls $CUSTOM_DIR)" && (
        cp -Ru "$CUSTOM_DIR" "$WORKDIR"
        # TODO: overwrite?
        # TODO: backup?
        # TODO: copy missing back? cp -au "$WORKDIR"/custom "$CUSTOM_DIR"/..
        # TODO: check for multiple USB?
        dcc down
        # TODO: maybe don't bring container down?
        dcc build --pull base && dcc build core conjuring && dcc up -d conjuring
      )
    fi
    sleep 1
  done
}

# docker container with mounted shared folder(s)
dcc(){
  pushd $WORKDIR
  docker-compose $@
  popd
}
dcc build --pull base && dcc build core conjuring && dcc up -d conjuring

usb_monitor &
wait
