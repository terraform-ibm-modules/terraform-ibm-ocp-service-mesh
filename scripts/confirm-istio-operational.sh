#!/usr/bin/env bash
# This script is designed to verify that all key components of Istio control plane are up and running.
# This is needs before apps with inject-sidecar are deployed

set -e

namespace="${1}"
service="${2}"
fail=false

# if service is not set using default value
if [[ -z "${service}" ]]; then
  service="istio-ingressgateway"
fi

echo "Checking istio ingressgateway with name ${service} is fully deployed in namespace ${namespace}"

# sleep 60 seconds initially to provide time for each deployment to get created
sleep 60

# Get list of deployments in control plane namespace
DEPLOYMENTS=()
while IFS='' read -r line; do DEPLOYMENTS+=("$line"); done < <(kubectl get deployments -n "${namespace}" --no-headers | cut -f1 -d ' ')

# Wait for all deployments to come up - timeout after 5 mins
# shellcheck disable=SC2068
for dep in ${DEPLOYMENTS[@]}; do
  if ! kubectl rollout status deployment "$dep" -n "${namespace}" --timeout 5m; then
    fail=true
  fi
done

# Ensure the load balancer hostname is set
counter=0
wait=30
retries=60 # 60 x 30 = 1800 secs = 30 mins
ext_hostname=""
while [ -z "${ext_hostname}" ]; do

  # Get the hostname from the kube service (retry needed on service lookup, as sometimes service may not exist yet)
  attempts=20 # 20 x 30 = 600 secs = 10 mins
  n=0
  until [ "$n" -ge $attempts ]; do
    ext_hostname=$(kubectl get svc "${service}" -n "${namespace}" --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}") && break
    n=$((n+1))
    if [ "$n" = $attempts ]; then
      echo "Maximum attempts reached for gateway ${service} in namespace ${namespace}. Giving up!"
      exit 1
    else
      echo "Retrying in ${wait} secs .."
      sleep ${wait}
    fi
  done

  # If not set yet, retry
  if [ -z "${ext_hostname}" ]; then
    # Give up when number of retries are reached
    if [ ${counter} == ${retries} ]; then
      echo "ERROR: Unable to detect external hostname for ${service} in namespace ${namespace}"
      fail=true
      break
    fi
    counter=$((counter+1))
    sleep ${wait}
  else
    # break the loop if hostname value detected
    echo "istio gateway ${service} in namespace ${namespace} assigned with hostname: ${ext_hostname}"
    # TODO: Add some health checks against the LB
    break
  fi
done

# Fail with some debug prints if issues detected
if [ ${fail} == true ]; then
  echo "Problem detected with istio gateway ${service} in namespace ${namespace}. Printing some debug info.."
  set +e
  kubectl get svc -n "${namespace}" -o wide
  kubectl get deployments -n "${namespace}" -o wide
  kubectl get pods -n "${namespace}" -o wide
  kubectl describe svc "${service}" -n "${namespace}"
  kubectl describe svc "${service}" -n "${namespace}"
  # exit 1
fi
