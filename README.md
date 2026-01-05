# Terraform AWS EKS with ArgoCD GitOps

This repository contains a comprehensive Terraform setup to provision a production-ready AWS EKS cluster with a full GitOps workflow powered by ArgoCD.

## Overview

This project automates the creation of a complete Kubernetes environment on AWS, including:

-   **Core Infrastructure**: A multi-AZ VPC, private and public subnets, and an EKS (Elastic Kubernetes Service) cluster.
-   **Container Infrastructure**: ECR for private container image storage.
-   **Database**: A managed AWS RDS instance.
-   **Observability Stack**: A full observability stack including Grafana, Prometheus, Loki, and Mimir.
-   **GitOps Engine**: ArgoCD for managing all Kubernetes applications and configurations directly from this Git repository.
-   **Auto-Scaling**: Karpenter for intelligent and efficient node provisioning.

## Architecture

The architecture is designed around the principle of "infrastructure as code" for the underlying AWS resources and "GitOps" for everything that runs on Kubernetes.

### Terraform for Infrastructure

Terraform is used to provision all the AWS resources, including the EKS cluster itself, the VPC, subnets, IAM roles, S3 buckets, and the initial deployment of ArgoCD. This ensures the foundational infrastructure is reproducible and version-controlled.

### ArgoCD for GitOps

ArgoCD is the heart of the deployment process for applications running on Kubernetes. It follows the "App of Apps" pattern:

1.  **Bootstrap**: Terraform deploys ArgoCD into the cluster.
2.  **App of Apps**: A parent ArgoCD application (this chart) is deployed via Helm, which in turn deploys all other applications.
3.  **Declarative Management**: The Helm chart in `k8s/argocd-applications` reads the `values.yaml` file to declaratively manage all other `Applications` and `AppProjects` within ArgoCD.

This means that to add or modify an application, you only need to change the YAML files in this repository and push the changes. ArgoCD will automatically sync the cluster state with the state defined in Git.

### Wave-based Deployments

To manage dependencies between different components (e.g., deploying the observability stack before the applications that use it), deployments are organized into "waves". Waves are processed in ascending order, ensuring a predictable deployment sequence.

-   **Wave -2:** ArgoCD Projects
-   **Wave -1:** Namespaces
-   **Wave 0:** Core Infrastructure (e.g., AWS LB Controller, Karpenter, Gatekeeper)
-   **Wave 1:** Core Services (e.g., Istiod, Gatekeeper Policies)
-   **Wave 2:** Observability Stack (e.g., Prometheus, Loki, Mimir)
-   **Wave 3:** Gateways & Routing
-   **Wave 5:** Business Apps / AI SRE

## Project Structure
```
.
├── infrastructure/
│   ├── environments/  # Main Terraform configurations per environment
│   └── modules/       # Reusable Terraform modules (EKS, VPC, RDS, etc.)
└── k8s/
    └── argocd-applications/ # Helm chart for the "App of Apps" pattern
        ├── templates/     # Templates for ArgoCD Applications and Projects
        │   ├── apps/      # ArgoCD Application definitions
        │   └── namespaces/ # Namespace definitions
        └── values.yaml    # The single source of truth for all apps and projects
```

## Prerequisites

-   AWS CLI configured with appropriate credentials.
-   Terraform >= 1.0.0
-   `kubectl` for interacting with the Kubernetes cluster.
-   `helm` for package management.

## Deployment

This project utilizes a multi-stage deployment process.

### 1. Provision AWS Infrastructure with Terraform

This stage provisions all the necessary AWS cloud resources, including the EKS cluster, VPC, RDS database, S3 buckets, and IAM roles.

1.  **Configure Your Environment**:
    All environment-specific configuration is located in the `infrastructure/environments/dev/terraform.tfvars` file. You must review and update this file with your desired settings.

2.  **Navigate to the Environments Directory**:
    ```bash
    cd infrastructure/environments
    ```

3.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

4.  **Plan and Apply the Infrastructure**:
    ```bash
    terraform plan -var-file="dev/terraform.tfvars"
    terraform apply -var-file="dev/terraform.tfvars"
    ```

5.  **Retrieve Terraform Outputs**:
    After successful application, retrieve the outputs in JSON format. These outputs contain the critical information needed for subsequent stages.
    ```bash
    terraform output -json > infrastructure/environments/tf_outputs.json
    ```

### 2. Configure kubectl and Install CRDs

Before deploying any applications, you must configure `kubectl` to communicate with your new EKS cluster and install the necessary Custom Resource Definitions (CRDs).

1.  **Configure `kubectl`**:
    ```bash
    aws eks --region eu-central-1 update-kubeconfig --name gustavo
    ```

2.  **Run the CRD Installation Script**:
    A helper script is provided to install all required CRDs from their official sources.
    ```bash
    ./k8s/crds/install-crds.sh
    ```
### Stage 2: Deploy Core Kubernetes Services (e.g., StorageClass) with Helm

This stage deploys foundational Kubernetes services that might be required before ArgoCD itself, such as the StorageClass.

1.  **Ensure `helm` is Installed**: Make sure you have the `helm` CLI installed.

2.  **Deploy EBS CSI StorageClass**: This deploys the `gp3-secure` StorageClass.
    ```bash
    helm upgrade --install ebs-csi-storage-class k8s/ebs-csi-storage-class \
      --namespace kube-system # StorageClasses are cluster-wide, but Helm needs a namespace for release tracking
    ```
    **Note**: You might need to configure `kubectl` before this step. You can use the command from Stage 1, step 3 to configure it.
### 3. Deploy ArgoCD Core and Applications with Helm

This stage deploys ArgoCD Core and then all other Kubernetes-native applications via the "App of Apps" pattern.

1.  **Deploy ArgoCD Core Helm Chart**: This installs the core ArgoCD components.

    ```bash
    helm upgrade --install argocd-core k8s/argocd-core \
      --namespace argocd --create-namespace \
      --set installCRDs=false \
      --set argo-cd.crds.install=false \
      --set argo-cd.applicationSet.enabled=false \
      --set argo-cd.notifications.enabled=false
    ```

2.  **Deploy ArgoCD Applications Helm Chart**: This deploys the `argocd-applications` chart, which will in turn deploy all other applications defined within it.

    ```bash
    helm upgrade --install argocd-applications k8s/argocd-applications \
      --namespace argocd --create-namespace \
      --set eksClusterEndpoint=$(jq -r .eks_cluster_endpoint.value infrastructure/environments/tf_outputs.json) \
      --set eksClusterCaCertificate=$(jq -r .eks_cluster_ca_certificate.value infrastructure/environments/tf_outputs.json) \
      --set eksClusterName=$(jq -r .eks_cluster_name.value infrastructure/environments/tf_outputs.json) \
      --set lokiBucketName=$(jq -r .loki_bucket_name.value infrastructure/environments/tf_outputs.json) \
      --set mimirBucketName=$(jq -r .mimir_bucket_name.value infrastructure/environments/tf_outputs.json) \
      --set awsRegion=$(jq -r .aws_region.value infrastructure/environments/tf_outputs.json) \
      --set vpcId=$(jq -r .vpc_id.value infrastructure/environments/tf_outputs.json) \
      --set dbSecretArn=$(jq -r .db_secret_arn.value infrastructure/environments/tf_outputs.json) \
      --set dbUrl=$(jq -r .db_url.value infrastructure/environments/tf_outputs.json) \
      --set dbPort=$(jq -r .db_port.value infrastructure/environments/tf_outputs.json) \
      --set karpenterNodeIamRoleName=$(jq -r .karpenter_node_iam_role_name.value infrastructure/environments/tf_outputs.json) \
      --set karpenterControllerIamRoleArn=$(jq -r .karpenter_controller_iam_role_arn.value infrastructure/environments/tf_outputs.json) \
      --set karpenterInterruptionQueueName=$(jq -r .karpenter_interruption_queue_name.value infrastructure/environments/tf_outputs.json) \
      --set lokiServiceAccountRoleArn=$(jq -r .loki_service_account_role_arn.value infrastructure/environments/tf_outputs.json) \
      --set lokiServiceAccountName=$(jq -r .loki_service_account_name.value infrastructure/environments/tf_outputs.json) \
      --set mimirServiceAccountRoleArn=$(jq -r .mimir_service_account_role_arn.value infrastructure/environments/tf_outputs.json) \
      --set mimirServiceAccountName=$(jq -r .mimir_service_account_name.value infrastructure/environments/tf_outputs.json) \
      --set kubePrometheusRelease="kube-prometheus-stack" \
      --set grafanaAdminPasswordParameterName=$(jq -r .grafana_admin_password_parameter.value infrastructure/environments/tf_outputs.json) \
      --set gitRepo.url="https://github.com/GustavoGuima86/terraform-aws-kubernetes" \
      --set gitRepo.branch="new-2026-features"
    ```

## Adding a New Application

To deploy a new application to the EKS cluster:

1.  **Create an Application Definition**: Create a new YAML file in the `k8s/argocd-applications/templates/apps/` directory. This file should be an ArgoCD `Application` resource.
2.  **Add Sync Wave Annotation**: Add an `argocd.argoproj.io/sync-wave` annotation to the `metadata` section of your application definition to control the deployment order.
3.  **Commit and Push**: Commit the new file and push it to your Git repository.

ArgoCD will detect the new file and automatically deploy your new application.

## Configuration Issues and Recommendations

During the review of the ArgoCD configuration, the following issues and recommendations have been identified:

-   **Hardcoded Git Repository URL and Branch**: The Git repository URL and branch are hardcoded in every application definition file. This should be parameterized and taken from the `values.yaml` file to avoid manual updates in multiple files.
-   **Empty Helm Parameters**: Several applications have empty Helm parameters that should be populated from Terraform outputs. These values need to be passed down from the parent `argocd-applications` chart to the individual application charts.
-   **Inconsistent `repoURL` for gateway-api-crds**: The `gateway-api-crds` application points to an external repository and uses `HEAD` as the target revision, which is not recommended for production. It should be pinned to a specific version.
-   **Missing Secret Configuration**: The `db_secret_arn` from Terraform outputs is not being used in the `SecretProviderClass` for the database. The connection between the secret created by Terraform and the `SecretProviderClass` needs to be established.

## Cleanup

To destroy all the infrastructure created by this project, run the following command:

```bash
cd infrastructure/environments
terraform destroy --var-file="dev/terraform.tfvars"
```