#!/usr/bin/env bash
which conda
if [ $? -eq 0 ]; then
  conda $@
else
  /opt/conda/bin/conda $@
fi
