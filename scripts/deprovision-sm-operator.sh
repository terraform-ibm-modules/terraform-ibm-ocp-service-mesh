#!/usr/bin/env bash

# this script cleans up the operator according to the input parameters for
# 1 operator namespace
# 2 operator name
# 3 cluster host
# 4 client certificate
# 5 client key
# 6 cluster CA certificate
# it cleans up
# 1. the custom service version resources
# 2. the custom resource definitions
# 3. the operator itself

# enabling exit on errors
set -e
LOGFILE="/tmp/tfe_create_admin_user.log"

# Function to generate kubeconfig dynamically
generate_kubeconfig() {
  local HOST=$1
  local CLIENT_CERTIFICATE=$2
  local CLIENT_KEY=$3
  local CLUSTER_CA_CERTIFICATE=$4

  # Generate a random hash for the kubeconfig filename
  local RANDOM_HASH
  RANDOM_HASH=$(openssl rand -hex 8)
  local KUBECONFIG_FILE="/tmp/kubeconfig-${RANDOM_HASH}"

  echo "Generating temporary kubeconfig file: $KUBECONFIG_FILE"
  echo "Generating temporary kubeconfig file: $KUBECONFIG_FILE" >> "${LOGFILE}"

  # Convert PEM certificates to base64
  local CLIENT_CERT_B64
  CLIENT_CERT_B64=$(echo "$CLIENT_CERTIFICATE" | base64 | tr -d '\n')
  local CLIENT_KEY_B64
  CLIENT_KEY_B64=$(echo "$CLIENT_KEY" | base64 | tr -d '\n')

  # Create the kubeconfig file
  if [ -z "$CLUSTER_CA_CERTIFICATE" ]; then
    # If CA certificate is empty, use insecure-skip-tls-verify
    cat > "$KUBECONFIG_FILE" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: $HOST
  name: cluster
contexts:
- context:
    cluster: cluster
    user: admin
  name: admin-context
current-context: admin-context
users:
- name: admin
  user:
    client-certificate-data: $CLIENT_CERT_B64
    client-key-data: $CLIENT_KEY_B64
EOF
  else
    # If CA certificate exists, use it
    local CA_CERT_B64
    CA_CERT_B64=$(echo "$CLUSTER_CA_CERTIFICATE" | base64 | tr -d '\n')
    cat > "$KUBECONFIG_FILE" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_CERT_B64
    server: $HOST
  name: cluster
contexts:
- context:
    cluster: cluster
    user: admin
  name: admin-context
current-context: admin-context
users:
- name: admin
  user:
    client-certificate-data: $CLIENT_CERT_B64
    client-key-data: $CLIENT_KEY_B64
EOF
  fi

  # Export the kubeconfig
  export KUBECONFIG="$KUBECONFIG_FILE"
  echo "KUBECONFIG set to: $KUBECONFIG_FILE"
  echo "KUBECONFIG set to: $KUBECONFIG_FILE" >> "${LOGFILE}"
}

# Generate kubeconfig from the provided credentials
generate_kubeconfig "$3" "$4" "$5" "$6"

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

if kubectl get crds -oname | grep 'maistra\.io'; then
    echo "Detected SM v2 -> deleting ONLY '*.sailoperator.io' CRDs"
    kubectl get crds -oname | grep sailoperator.io | xargs -r kubectl delete
else
    echo "SM v2 NOT detected -> deleting ONLY '*.sailoperator.io' CRDs"
    kubectl get crds -oname | grep -e istio.io -e sailoperator.io | xargs kubectl delete
fi

echo "Deleting operator ${operator_name} in namespace ${operator_namespace}"
echo "Deleting operator ${operator_name} in namespace ${operator_namespace}" >> "${LOGFILE}"

kubectl delete operator "${operator_name}"."${operator_namespace}"

echo "Deprovisioning of ${operator_name} from namespace ${operator_namespace} completed"
echo "Deprovisioning of ${operator_name} from namespace ${operator_namespace} completed" >> "${LOGFILE}"

echo "Completed deprovision-sm-operator.sh at $(date '+%Y-%m-%d %H:%M:%S')"
echo "Completed deprovision-sm-operator.sh at $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOGFILE}"

# Clean up the temporary kubeconfig file
if [ -n "$KUBECONFIG" ] && [ -f "$KUBECONFIG" ]; then
  echo "Cleaning up temporary kubeconfig file: $KUBECONFIG"
  echo "Cleaning up temporary kubeconfig file: $KUBECONFIG" >> "${LOGFILE}"
  rm -f "$KUBECONFIG"
fi

set +e
