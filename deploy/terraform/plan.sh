#!/bin/bash
terraform get

APPLY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

terraform plan \
  -var-file=<(lpass show --notes "${1}") \
  ${APPLY_DIR}
