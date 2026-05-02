#!/usr/bin/env bash
# This script is designed to verify that all key components of Istio dataplane for ingress gateway are up and running.
# This is needed before apps with inject-sidecar are deployed

set -e

namespace="${1}"
service="${2}"
lb_type="${3:-alb}"
fail=false
initialsleep=15

# if service is not set using default value
if [[ -z "${service}" ]]; then
  service="istio-ingressgateway"
fi

echo "Checking ingress gateway ${service} successful deployment in namespace ${namespace} for load balancer type ${lb_type}"

echo "Initial sleep of ${initialsleep} seconds before starting to check"
sleep "${initialsleep}"

echo "Checking deployments ${service} in namespace ${namespace}"

DEPLOYMENTS=()
while IFS='' read -r line; do DEPLOYMENTS+=("$line"); done < <(kubectl get deployment "${service}" -n "${namespace}" --no-headers 2>/dev/null | cut -f1 -d ' ' || true)

# Wait for all deployments to come up - timeout after 5 mins
# shellcheck disable=SC2068
for dep in ${DEPLOYMENTS[@]}; do
  echo "Checking deployment ${dep} status in namespace ${namespace}"
  if ! kubectl rollout status deployment "$dep" -n "${namespace}" --timeout 5m; then
    echo "Deployment ${dep} in namespace ${namespace} seems failing to deploy"
    fail=true
  fi
done


# Ensure the load balancer is ready based on type
counter=0
sleeptime=30
max_retries=60  # 60 x 30 = 1800 secs = 30 mins
lb_ready=false

echo "Waiting for load balancer to be assigned (type: ${lb_type})..."

while [ ${counter} -lt ${max_retries} ]; do
  # Check based on load balancer type
  case "${lb_type}" in
    alb)
      # For ALB, check for hostname
      lb_value=$(kubectl get svc "${service}" -n "${namespace}" --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}" 2>/dev/null || echo "")
      if [ -n "${lb_value}" ]; then
        echo "Ingress gateway ${service} in namespace ${namespace} assigned with hostname: ${lb_value}"
        lb_ready=true
      fi
      ;;
    nlb)
      # For NLB, check for IP
      lb_value=$(kubectl get svc "${service}" -n "${namespace}" --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}" 2>/dev/null || echo "")
      if [ -n "${lb_value}" ]; then
        echo "Ingress gateway ${service} in namespace ${namespace} assigned with IP: ${lb_value}"
        lb_ready=true
      fi
      ;;
    other)
      # For other types, check for one or more IPs
      ingress_count=$(kubectl get svc "${service}" -n "${namespace}" -o json 2>/dev/null | jq -r '.status.loadBalancer.ingress | length' 2>/dev/null || echo "0")
      if [ "${ingress_count}" -gt 0 ]; then
        lb_ips=$(kubectl get svc "${service}" -n "${namespace}" -o json 2>/dev/null | jq -r '.status.loadBalancer.ingress[].ip' 2>/dev/null | tr '\n' ' ' || echo "")
        echo "Ingress gateway ${service} in namespace ${namespace} assigned with ${ingress_count} IP(s): ${lb_ips}"
        lb_ready=true
      fi
      ;;
    *)
      echo "ERROR: Unknown load balancer type: ${lb_type}"
      fail=true
      break
      ;;
  esac

  # If ready, break out of loop
  if [ "${lb_ready}" = true ]; then
    break
  fi

  # Increment counter and check if max retries reached
  counter=$((counter+1))
  if [ ${counter} -eq ${max_retries} ]; then
    echo "ERROR: Unable to detect load balancer details for ${service} in namespace ${namespace} (type: ${lb_type}) after ${max_retries} attempts"
    fail=true
    break
  fi

  echo "Attempt ${counter}/${max_retries}: Load balancer not ready yet, retrying in ${sleeptime} secs..."
  sleep "${sleeptime}"
done

# Fail with some debug prints if issues detected
if [ ${fail} == true ]; then
  echo "Problem detected with gateway ${service} in namespace ${namespace}. Printing some debug info.."
  set +e
  kubectl get svc -n "${namespace}" -o wide
  kubectl get deployment "${service}" -n "${namespace}" -o wide 2>/dev/null || echo "No deployment found"
  kubectl get pods -n "${namespace}" -o wide
  kubectl describe svc "${service}" -n "${namespace}"
  exit 1
fi

echo "Ingress gateway ${service} in namespace ${namespace} is operational"
