#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function print_var() {
  echo "${var_value}"
}

print_var
