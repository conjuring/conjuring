#!/usr/bin/env bash
shopt -s extglob
set -e

if [ ${#} -lt 2 ]; then
  echo "Usage: env2conda <condabin> <environment.yml>..."
  exit 1
fi

conda=$1
env_files="${@:2}"

prefix="$($conda info --base)"

for f in $env_files; do
  if [ ! -f $f ]; then
    echo "E:$(date -Is):$0:could not find $f" 1>&2
    continue
  fi
  # get env name from file
  env=$(sed -nr 's/^name:\s+(\S+).*$/\1/p' "$f")
  # backup (1): get env name from filename
  env_f=$(basename "$f")
  env_f=${env_f/*environment?([-_])/}
  env_f=${env_f/.y?(a)ml/}
  env=${env:-${env_f}}
  # backup (2): set env=base
  env=${env:-base}
  # create/update env
  echo "I:$(date -Is):$0:$conda env update -n $env -f=$f" 1>&2
  $conda env update -n $env -f=$f
  # install kernel
  if [ $env != base ]; then
    $conda install -n $env -y ipykernel
    source "$prefix/bin/activate" $env
    python -m ipykernel install --prefix="$prefix" --name $env
    conda deactivate
  fi
done
