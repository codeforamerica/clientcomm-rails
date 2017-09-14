#!/bin/bash

APPLY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

terraform apply \
  -var-file=<(lpass show --notes "${1}") \
  ${APPLY_DIR}
