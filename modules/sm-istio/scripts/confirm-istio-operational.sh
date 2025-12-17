#!/usr/bin/env bash
# This script is designed to verify that all key components of Istio control plane are up and running.
# This is needed before workload is deployed and injected

set -e

namespace="${1}"
name="${2}"
fail=false
initialsleep=15

echo "Checking istiod ${name} successful deployment in namespace ${namespace}"

echo "Initial sleep of ${initialsleep} seconds before starting to check"
sleep "${initialsleep}"

echo "Checking deployments in namespace ${namespace}"
# Get list of deployments in control plane namespace
DEPLOYMENTS=()
while IFS='' read -r line; do DEPLOYMENTS+=("$line"); done < <(kubectl get deployments -n "${namespace}" --no-headers | cut -f1 -d ' ')

# Wait for all deployments to come up - timeout after 5 mins
# shellcheck disable=SC2068
for dep in ${DEPLOYMENTS[@]}; do
  echo "Checking deployment ${dep} status in namespace ${namespace}"
  if ! kubectl rollout status deployment "$dep" -n "${namespace}" --timeout 5m; then
    echo "Deployment ${dep} in namespace ${namespace} seems to fail to deploy"
    fail=true
  fi
done

# checking istio svc to be successfully deployed
wait=30
clusterIP=""
# istiod svc named istiod if name is default otherwise istiod-name
if [[ "${name}" == "default" ]]; then
  istiodsvc="istiod"
else
  istiodsvc="istiod-${name}"
fi

echo "Checking for istiod svc ${istiodsvc} in namespace ${namespace} correctly deployed"
while [ -z "${clusterIP}" ]; do
  # Get the hostname from the kube service (retry needed on service lookup, as sometimes service may not exist yet)
  attempts=10 # 10 x 30 = 300 secs = 5 mins
  n=1
  until [ "$n" -gt $attempts ]; do
    echo "Attempt # ${n}"
    clusterIP=$(kubectl get svc "${istiodsvc}" -n "${namespace}" --template="{{.spec.clusterIP}}") && echo "istiod svc ${istiodsvc} in namespace ${namespace} correctly deployed" && break
    n=$((n+1))
    if [ "$n" -gt $attempts ]; then
      echo "Maximum attempts ${attempts} reached for gateway ${istiodsvc} in namespace ${namespace}. Giving up!"
      fail=true
      exit 1
    else
      echo "Retrying in ${wait} secs .."
      sleep ${wait}
    fi
  done

done

# Fail with some debug prints if issues detected
if [ ${fail} == true ]; then
  echo "Problem detected with istiod deployments or istiod svc ${istiodsvc} in namespace ${namespace}. Printing some debug info.."
  set +e
  kubectl get svc -n "${namespace}" -o wide
  kubectl get deployments -n "${namespace}" -o wide
  kubectl get pods -n "${namespace}" -o wide
  kubectl describe svc "${istiodsvc}" -n "${namespace}"
  kubectl describe deployments -n "${namespace}"
  # exit 1
fi
