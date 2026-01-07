#!/usr/bin/env bash

# this script cleans up the operator according to the input parameters for
# 1 kubeconfig to login on the cluster
# 2 operator namespace
# 3 operatorn name
# it cleans up
# 1. the custom service version resources
# 2. the custom resource definitions
# 3. the operator itself

# enabling exit on errors
set -e

echo "Start deprovision-sm-operator.sh with ${1} ${2} ${3}"
kubeconfig="${1}"
export KUBECONFIG="${kubeconfig}"
operator_namespace="${2:-openshift-operators}"
operator_name="${3:-servicemeshoperator3}"

echo "Fetching and deleting CSVs for ${operator_name} operator subscription in namespace ${operator_namespace}"

CSV="$(kubectl get clusterserviceversion -n "${operator_namespace}" | grep servicemeshoperator3 | awk '{print $1}')"

if [ -n "$CSV" ]
then
    echo "Deleting CSV ${CSV} in namespace ${operator_namespace}"
    kubectl delete csv "$CSV" -n "${operator_namespace}"
fi

echo "Deleting all CRDs from istio operator"

kubectl get crds -oname | grep -e istio.io -e sailoperator.io | xargs kubectl delete

echo "Deleting operator ${operator_name} in namespace ${operator_namespace}"

kubectl delete operator "${operator_name}"."${operator_namespace}"

echo "Deprovisioning of ${operator_name} from namespace ${operator_namespace} completed"

echo "Exit deprovision-sm-operator.sh"

set +e
