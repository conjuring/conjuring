#!/usr/bin/env bash
## Usage: conda.sh <cmd> ...
# Where <cmd> is any valid conda command, or `path_exec` (which will prefix
# the base conda bin path before running the remaining command)

if [ ${#} -gt 1 -a "$1" = path_exec ]; then
  PATH="$($0 info --base)/bin:$PATH" "${@:2}"
else
  which conda
  if [ $? -eq 0 ]; then
    conda $@
  else
    /opt/conda/bin/conda $@
  fi
fi
