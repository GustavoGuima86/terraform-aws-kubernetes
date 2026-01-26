#!/usr/bin/env bash
set -euo pipefail

echo "Installing Velero CRDs..."
VELERO_VERSION="v1.12.0"

# Install Velero CRDs for v1.12.0 (matches the deployed version)
# Note: v1.12.0 does NOT have DataDownload/DataUpload CRDs (those are v1.15+)
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_backups.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_backupstoragelocations.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_deletebackuprequests.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_downloadrequests.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_podvolumebackups.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_podvolumerestores.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_restores.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_schedules.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_serverstatusrequests.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_volumesnapshotlocations.yaml"
kubectl apply -f "https://raw.githubusercontent.com/vmware-tanzu/velero/${VELERO_VERSION}/config/crd/v1/bases/velero.io_backuprepositories.yaml"

# Note: v1.12.0 does NOT include:
# - velero.io_datadownloads (added in v1.15+)
# - velero.io_datauploads (added in v1.15+)
# These are part of the Data Mover functionality introduced in later versions

echo "Velero CRDs for v1.12.0 installed successfully."

echo "Installing Argo CD CRDs..."
kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v2.12.3"

echo "Installing Gateway API CRDs..."
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml"

#echo "Installing K8sGPT Operator and CRDs..."
#helm repo add k8sgpt https://charts.k8sgpt.ai/
#helm upgrade --install k8sgpt-operator k8sgpt/k8sgpt -n k8sgpt-operator-system --create-namespace

echo "Installing Gatekeeper CRDs..."

GATEKEEPER_VERSION="3.21.0"

mapfile -t CRDS < <(
  curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/open-policy-agent/gatekeeper/contents/charts/gatekeeper/crds?ref=v${GATEKEEPER_VERSION}" |
    jq -r '.[] | select(.name | endswith(".yaml")) | .name'
)

for crd in "${CRDS[@]}"; do
  crd_url="https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v${GATEKEEPER_VERSION}/charts/gatekeeper/crds/${crd}"
  curl -sSL "${crd_url}" |
    yq '.metadata.annotations."helm.sh/resource-policy" = "keep"' |
    kubectl apply --server-side -f -
done


echo "Installing Kube Prometheus Stack CRDs..."

CHART_VERSION="kube-prometheus-stack-80.9.2"

echo "Fetching CRD list for ${CHART_VERSION}..."

# 2. Get the list of CRD files via GitHub API
#    The CRDs are located in a subchart within the main chart directory.
mapfile -t CRDS < <(
  curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/prometheus-community/helm-charts/contents/charts/kube-prometheus-stack/charts/crds/crds?ref=${CHART_VERSION}" |
    jq -r '.[] | select(.name | endswith(".yaml")) | .name'
)

if [ ${#CRDS[@]} -eq 0 ]; then
  echo "Error: No CRDs found. Check the CHART_VERSION or the repository path."
  exit 1
fi

echo "Found ${#CRDS[@]} CRDs. Installing..."

# 3. Loop through each file, inject the annotation, and apply
for crd in "${CRDS[@]}"; do
  # Construct the raw file URL
  crd_url="https://raw.githubusercontent.com/prometheus-community/helm-charts/${CHART_VERSION}/charts/kube-prometheus-stack/charts/crds/crds/${crd}"

  echo "Applying ${crd}..."

  curl -sSL "${crd_url}" |
    # Add the annotation so Helm doesn't delete these CRDs if you uninstall the chart
    yq '.metadata.annotations."helm.sh/resource-policy" = "keep"' |
    # Use server-side apply because Prometheus CRDs are huge and can exceed client-side limits
    kubectl apply --server-side -f -
done

echo "All Kube Prometheus Stack CRDs installed successfully."

echo "Installing Kagent CRDs..."
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds --version 0.7.8


