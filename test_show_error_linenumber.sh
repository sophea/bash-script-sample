#!/bin/bash

set -eE -o functrace

file1=f1
file2=f2
file3=f3
file4=f4

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
  echo $
}
#trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
trap 'rc=$?; echo "error code $rc at line $LINENO" "$BASH_COMMAND"; exit $rc' ERR

cp -- "$file1" "$file2"
cp -- "$file3" "$file4"
