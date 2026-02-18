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
LOGFILE="/tmp/tfe_create_admin_user.log"

echo "Start deprovision-sm-operator.sh with ${1} ${2} at $(date '+%Y-%m-%d %H:%M:%S')"
echo "Start deprovision-sm-operator.sh with ${1} ${2} at $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOGFILE}"

echo "Sleeping for 60s before starting deprovisioning to allow previous resources to complete undeployment"
echo "Sleeping for 60s before starting deprovisioning to allow previous resources to complete undeployment" >> "${LOGFILE}"
sleep 60

operator_namespace="${1:-openshift-operators}"
operator_name="${2:-servicemeshoperator3}"

echo "Fetching and deleting CSVs for ${operator_name} operator subscription in namespace ${operator_namespace}"
echo "Fetching and deleting CSVs for ${operator_name} operator subscription in namespace ${operator_namespace}" >> "${LOGFILE}"
sleep 60

CSV="$(kubectl get clusterserviceversion -n "${operator_namespace}" | grep servicemeshoperator3 | awk '{print $1}')"

if [ -n "$CSV" ]
then
    echo "Deleting CSV ${CSV} in namespace ${operator_namespace}"
    echo "Deleting CSV ${CSV} in namespace ${operator_namespace}" >> "${LOGFILE}"
    kubectl delete csv "$CSV" -n "${operator_namespace}"
fi

echo "Deleting all CRDs from istio operator"
echo "Deleting all CRDs from istio operator" >> "${LOGFILE}"

kubectl get crds -oname | grep -e istio.io -e sailoperator.io | xargs kubectl delete

echo "Deleting operator ${operator_name} in namespace ${operator_namespace}"
echo "Deleting operator ${operator_name} in namespace ${operator_namespace}" >> "${LOGFILE}"

kubectl delete operator "${operator_name}"."${operator_namespace}"

echo "Deprovisioning of ${operator_name} from namespace ${operator_namespace} completed"
echo "Deprovisioning of ${operator_name} from namespace ${operator_namespace} completed" >> "${LOGFILE}"

echo "Completed deprovision-sm-operator.sh at $(date '+%Y-%m-%d %H:%M:%S')"
echo "Completed deprovision-sm-operator.sh at $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOGFILE}"

set +e
