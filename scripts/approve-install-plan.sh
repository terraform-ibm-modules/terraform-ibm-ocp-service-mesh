#!/usr/bin/env bash

## Subscriptions are set for manual approval. This script approves the first installplan for the initial install

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/approve-install-plan-functions.sh"

namespace="$1"

if [[ -z $2 ]]; then
    operator_installplan_timeout=1200
else
    operator_installplan_timeout=$2
fi

### getting list of the operators installed
echo "Retrieving subscriptions from namespace ${namespace}"
OPERATORS=$(oc get subscriptions -n "${namespace}" -o jsonpath="{$.items[*].metadata.name}")
## Wait for, and approve install plan for each operator installed
# shellcheck disable=SC2068
for operator in ${OPERATORS[@]}
do
    echo "Approving plan for operator ${operator} in namespace ${namespace} with timeout ${operator_installplan_timeout}"
    approve_install_plan "${operator}" "${namespace}" "${operator_installplan_timeout}"
done

## Post install waits for each operator installed
# shellcheck disable=SC2068
for operator in ${OPERATORS[@]}
do
    echo "Waiting for operator ${operator} in namespace ${namespace} to be ready"
    wait_for_operator "${operator}" "$namespace"
done

echo "Operators installation complete in namespace ${namespace}"
