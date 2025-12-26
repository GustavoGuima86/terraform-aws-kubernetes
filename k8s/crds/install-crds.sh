#!/bin/bash
set -euo pipefail

echo "Installing Argo CD CRDs..."
kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v2.11.2"

echo "Installing Gateway API CRDs..."
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml"

#echo "Installing K8sGPT Operator and CRDs..."
#helm repo add k8sgpt https://charts.k8sgpt.ai/
#helm upgrade --install k8sgpt-operator k8sgpt/k8sgpt -n k8sgpt-operator-system --create-namespace

echo "All required CRDs have been installed."