#!/usr/bin/env bash
# This script is designed to verify that all key components of Istio dataplane for egress gateway are up and running.
# This is needed before workload is deployed and injected

set -e

namespace="${1}"
service="${2}"
fail=false
initialsleep=15

echo "Checking egress gateway ${service} successful deployment in namespace ${namespace}"

echo "Initial sleep of ${initialsleep} seconds before starting to check"
sleep "${initialsleep}"

echo "Checking deployment ${service} in namespace ${namespace}"
# Get list of deployments in control plane namespace
DEPLOYMENTS=()
while IFS='' read -r line; do DEPLOYMENTS+=("$line"); done < <(kubectl get deployment "${service}" -n "${namespace}" --no-headers | cut -f1 -d ' ')

# Wait for all deployments to come up - timeout after 5 mins
# shellcheck disable=SC2068
for dep in ${DEPLOYMENTS[@]}; do
  echo "Checking deployment ${dep} status in namespace ${namespace}"
  if ! kubectl rollout status deployment "$dep" -n "${namespace}" --timeout 5m; then
    echo "Deployment ${dep} in namespace ${namespace} seems to fail to deploy"
    fail=true
  fi
done

sleeptime=30
echo "Checking for svc ${service} in namespace ${namespace} correctly deployed"
while [ -z "${clusterIP}" ]; do
  # Get the clusterIP from the kube service (retry needed on service lookup, as sometimes service may not exist yet)
  attempts=10 # 10 x 30 = 300 secs = 5 mins
  n=1
  until [ "$n" -gt $attempts ]; do
    echo "Attempt # ${n}"
    clusterIP=$(kubectl get svc "${service}" -n "${namespace}" --template="{{.spec.clusterIP}}") && echo "${service} svc in namespace ${namespace} correctly deployed" && break
    n=$((n+1))
    if [ "$n" -gt $attempts ]; then
      echo "Maximum attempts ${attempts} reached for gateway ${service} in namespace ${namespace}. Giving up!"
      fail=true
      exit 1
    else
      echo "Retrying in ${sleeptime} secs .."
      sleep "${sleeptime}"
    fi
  done

done

# Fail with some debug prints if issues detected
if [ ${fail} == true ]; then
  echo "Problem detected with deployments of gateway ${service} in namespace ${namespace}. Printing some debug info.."
  set +e
  kubectl get svc -n "${namespace}" -o wide
  kubectl get deployment "${service}" -n "${namespace}" -o wide
  kubectl get pods -n "${namespace}" -o wide
  kubectl describe svc "${service}" -n "${namespace}"
  kubectl describe deployments "${service}" -n "${namespace}"
  # exit 1
fi
