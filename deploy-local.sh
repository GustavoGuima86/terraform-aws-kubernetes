#!/bin/bash
set -euo pipefail

# Define Istio version (can be made configurable)
ISTIO_VERSION="1.28.0"

echo "Deploying ArgoCD with local changes (bypassing GitOps source for applications)..."

# Check if tf_outputs.json exists
if [ ! -f "infrastructure/environments/tf_outputs.json" ]; then
    echo "Error: tf_outputs.json not found. Please ensure Terraform outputs are available at infrastructure/environments/tf_outputs.json."
    exit 1
fi

TF_OUTPUTS_FILE="infrastructure/environments/tf_outputs.json"

# Read values from tf_outputs.json
EKS_CLUSTER_ENDPOINT=$(jq -r '.eks_cluster_endpoint.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${EKS_CLUSTER_ENDPOINT}" ]; then
  echo "Error: eks_cluster_endpoint not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

EKS_CLUSTER_CA_CERTIFICATE=$(jq -r '.eks_cluster_ca_certificate.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${EKS_CLUSTER_CA_CERTIFICATE}" ]; then
  echo "Error: eks_cluster_ca_certificate not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

EKS_CLUSTER_NAME=$(jq -r '.eks_cluster_name.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${EKS_CLUSTER_NAME}" ]; then
  echo "Error: eks_cluster_name not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

LOKI_BUCKET_NAME=$(jq -r '.loki_bucket_name.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${LOKI_BUCKET_NAME}" ]; then
  echo "Error: loki_bucket_name not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

MIMIR_BUCKET_NAME=$(jq -r '.mimir_bucket_name.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${MIMIR_BUCKET_NAME}" ]; then
  echo "Error: mimir_bucket_name not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

AWS_REGION=$(jq -r '.aws_region.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${AWS_REGION}" ]; then
  echo "Error: aws_region not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

VPC_ID=$(jq -r '.vpc_id.value // empty' "${TF_OUTPUTS_FILE}")
if [ -z "${VPC_ID}" ]; then
  echo "Error: vpc_id not found in tf_outputs.json. Please ensure Terraform outputs are correct."
  exit 1
fi

# Optional values (handle cases where they might not exist)
DB_SECRET_ARN=$(jq -r '.db_secret_arn.value // empty' "${TF_OUTPUTS_FILE}")
DB_URL=$(jq -r '.db_url.value // empty' "${TF_OUTPUTS_FILE}")
DB_PORT=$(jq -r '.db_port.value // empty' "${TF_OUTPUTS_FILE}")


# Execute helm upgrade command with local deploymentMethod
# Install ArgoCD Core components
helm dependency build ./k8s/argocd-core
helm upgrade --install argocd-core ./k8s/argocd-core \
  --namespace argocd --create-namespace \
  --set argo-cd.global.image.tag="v2.11.2" \
  --set argo-cd.server.ingress.hosts[0]="argocd.example.com"

# Install ArgoCD Applications and Projects
helm upgrade --install argocd-applications ./k8s/argocd-applications \
  -f ./k8s/argocd-applications/values.yaml \
  --namespace argocd \
  --set deploymentMethod="local" \
  --set argocdNamespace="argocd" \
  --set karpenter.settings.clusterEndpoint="${EKS_CLUSTER_ENDPOINT}" \
  --set karpenter.settings.clusterName="${EKS_CLUSTER_NAME}" \
  --set karpenter.settings.interruptionQueue="karpenter-${EKS_CLUSTER_NAME}" \
  --set eksClusterEndpoint="${EKS_CLUSTER_ENDPOINT}" \
  --set eksClusterCaCertificate="${EKS_CLUSTER_CA_CERTIFICATE}" \
  --set eksClusterName="${EKS_CLUSTER_NAME}" \
  --set lokiBucketName="${LOKI_BUCKET_NAME}" \
  --set mimirBucketName="${MIMIR_BUCKET_NAME}" \
  --set awsRegion="${AWS_REGION}" \
  --set vpcId="${VPC_ID}" \
  $( [ -n "${DB_SECRET_ARN}" ] && echo "--set dbSecretArn=${DB_SECRET_ARN}" ) \
  $( [ -n "${DB_URL}" ] && echo "--set dbUrl=${DB_URL}" ) \
  $( [ -n "${DB_PORT}" ] && echo "--set dbPort=${DB_PORT}" ) \
  --set istioVersion="${ISTIO_VERSION}" # Pass Istio version if needed in charts
echo "ArgoCD deployed with local changes. Applications will not sync from Git."

echo "To revert to GitOps mode, run:"
echo "helm upgrade --install argocd-core k8s/argocd-core \\"
echo "  --namespace argocd --create-namespace \\"
echo "  --set argo-cd.global.image.tag=\"v2.11.2\" \\"
echo "  --set argo-cd.server.ingress.hosts[0]=\"argocd.example.com\""
echo ""
echo "helm upgrade --install argocd-applications k8s/argocd-applications \\"
echo "  -f k8s/argocd-applications/values.yaml \\"
echo "  --namespace argocd \\"
echo "  --set deploymentMethod=\"gitops\" \\"
echo "  --set argocdNamespace=\"argocd\" \\"
echo "  # ... and all other necessary --set values as before"
