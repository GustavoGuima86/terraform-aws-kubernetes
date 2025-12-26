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

1.  **Bootstrap**: Terraform deploys ArgoCD into the cluster and creates a single ArgoCD `Application` resource called `wave-0-system`.
2.  **App of Apps**: This `wave-0-system` application points back to this Git repository, specifically to the `k8s/argocd` directory.
3.  **Declarative Management**: The Helm chart in this directory reads the `k8s/argocd/values.yaml` file to declaratively manage all other `Applications` and `AppProjects` within ArgoCD.

This means that to add or modify an application, you only need to change the YAML files in this repository and push the changes. ArgoCD will automatically sync the cluster state with the state defined in Git.

### Wave-based Deployments

To manage dependencies between different components (e.g., deploying the observability stack before the applications that use it), deployments are organized into "waves" in `k8s/argocd/values.yaml`. Waves are processed in ascending order, ensuring a predictable deployment sequence.

-   **Wave 0**: Deploys critical infrastructure and observability components (Karpenter, Loki, Mimir, etc.).
-   **Wave 1**: Deploys user-facing applications.

## Project Structure
```
.
├── infrastructure/
│   ├── environments/  # Main Terraform configurations per environment
│   └── modules/       # Reusable Terraform modules (EKS, VPC, RDS, etc.)
└── k8s/
    └── argocd/        # Helm chart for the "App of Apps" pattern
        ├── templates/ # Templates for ArgoCD Applications and Projects
        └── values.yaml# The single source of truth for all apps and projects
```

## Prerequisites

-   AWS CLI configured with appropriate credentials.
-   Terraform >= 1.0.0
-   `kubectl` for interacting with the Kubernetes cluster.
-   `helm` for package management (optional, for inspection).

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
    terraform output -json > tf_outputs.json
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
    This script will:
    - Install the CRDs for Argo CD (`Application`, `AppProject`).
    - Install the CRDs for the Kubernetes Gateway API (`HTTPRoute`, etc.).
    - Install the K8sGPT operator and its associated CRDs.

### 3. Deploy Core Kubernetes Services (e.g., StorageClass) with Helm

This stage deploys foundational Kubernetes services that might be required before ArgoCD itself, such as the StorageClass.

1.  **Deploy EBS CSI StorageClass**: This deploys the `gp3-secure` StorageClass.
    ```bash
    helm upgrade --install ebs-csi-storage-class k8s/ebs-csi-storage-class \
      --namespace kube-system # StorageClasses are cluster-wide, but Helm needs a namespace for release tracking
    ```

### 4. Deploy ArgoCD and Applications with Helm

This stage deploys ArgoCD and all other Kubernetes-native applications.

1.  **Deploy ArgoCD Helm Chart**: Use the `helm upgrade --install` command, passing the Terraform outputs using `--set` flags. This deploys ArgoCD, and ArgoCD will then manage the deployment of all other applications based on `k8s/argocd/values.yaml`.

    ```bash
    helm upgrade --install argocd k8s/argocd \
      --namespace $(jq -r .argocd_namespace.value tf_outputs.json) --create-namespace \
      --set eksClusterEndpoint=$(jq -r .eks_cluster_endpoint.value tf_outputs.json) \
      --set eksClusterCaCertificate=$(jq -r .eks_cluster_ca_certificate.value tf_outputs.json) \
      --set eksClusterName=$(jq -r .eks_cluster_name.value tf_outputs.json) \
      --set lokiBucketName=$(jq -r .loki_bucket_name.value tf_outputs.json) \
      --set mimirBucketName=$(jq -r .mimir_bucket_name.value tf_outputs.json) \
      --set awsRegion=$(jq -r .aws_region.value tf_outputs.json) \
      --set vpcId=$(jq -r .vpc_id.value tf_outputs.json) \
      --set dbSecretArn=$(jq -r .db_secret_arn.value tf_outputs.json) \
      --set dbUrl=$(jq -r .db_url.value tf_outputs.json) \      --set dbPort=$(jq -r .db_port.value tf_outputs.json) \
      --set argocdNamespace=$(jq -r .argocd_namespace.value tf_outputs.json) \
      --set gitRepo.url="https://github.com/GustavoGuima86/terraform-aws-kubernetes" \
      --set gitRepo.branch="main" \
      # ... add other argocd specific variables (e.g., argocd.createIngress, argocd.ingressClass) if needed
    ```

    **Note**: The example above assumes `argocd_namespace` is an output. Make sure all `--set` values correspond to outputs from `tf_outputs.json` or other configurations. For `gitRepo.url`, `gitRepo.branch` etc., you might set them directly if not output from Terraform.

## Local Deployment for Testing

For local development and testing without committing changes to Git, you can use the `deploy-local.sh` script. This script deploys the ArgoCD "App of Apps" Helm chart with a special flag (`deploymentMethod: local`) that tells the deployed ArgoCD applications *not* to synchronize from Git. This allows you to iteratively apply changes directly from your local machine.

### Prerequisites for Local Deployment

-   `jq` installed (for parsing `tf_outputs.json`).
-   `tf_outputs.json` generated from Stage 1.
-   `helm` CLI installed and configured with access to your Kubernetes cluster.

### How to Deploy Locally

1.  **Ensure `tf_outputs.json` is up to date**:
    ```bash
    cd infrastructure/environments
    terraform output -json > tf_outputs.json
    cd ../..
    ```

2.  **Run the local deployment script**:
    ```bash
    ./deploy-local.sh
    ```

    This command will:
    -   Read necessary values from `tf_outputs.json`.
    -   Execute `helm upgrade --install argocd k8s/argocd` with `deploymentMethod: local`.
    -   The ArgoCD applications deployed by this chart will *not* fetch their configurations from Git. Instead, they will reflect the state of your local `k8s/argocd` chart.

### Applying Further Local Changes

After running `./deploy-local.sh`, you can make changes to any of the Kubernetes manifests or Helm charts within your local repository. To apply these changes to your cluster, simply re-run `./deploy-local.sh`.

### Reverting to GitOps Mode

To switch back to the standard GitOps workflow (where ArgoCD continuously synchronizes from your Git repository), you need to run the `helm upgrade` command with `deploymentMethod: gitops`. The `deploy-local.sh` script provides the exact command in its output for convenience.

```bash
    helm upgrade --install argocd k8s/argocd \
      --namespace $(jq -r .argocd_namespace.value tf_outputs.json) --create-namespace \
      --set deploymentMethod="gitops" \
      --set eksClusterEndpoint=$(jq -r .eks_cluster_endpoint.value tf_outputs.json) \
      --set eksClusterCaCertificate=$(jq -r .eks_cluster_ca_certificate.value tf_outputs.json) \
      --set eksClusterName=$(jq -r .eks_cluster_name.value tf_outputs.json) \
      --set lokiBucketName=$(jq -r .loki_bucket_name.value tf_outputs.json) \
      --set mimirBucketName=$(jq -r .mimir_bucket_name.value tf_outputs.json) \
      --set awsRegion=$(jq -r .aws_region.value tf_outputs.json) \
      --set vpcId=$(jq -r .vpc_id.value tf_outputs.json) \
      --set dbSecretArn=$(jq -r .db_secret_arn.value tf_outputs.json) \
      --set dbUrl=$(jq -r .db_url.value tf_outputs.json) \
      --set dbPort=$(jq -r .db_port.value tf_outputs.json) \
      --set argocdNamespace=$(jq -r .argocd_namespace.value tf_outputs.json) \
      --set gitRepo.url="https://github.com/GustavoGuima86/terraform-aws-kubernetes" \
      --set gitRepo.branch="new-2026-features" \
      # ... include any other --set values required by your ArgoCD Helm chart
```

---
### 4. Accessing the Cluster and ArgoCD

Once the `terraform apply` and `helm upgrade` commands are complete:

1.  **Configure `kubectl`**:
    ```bash
    aws eks --region $(jq -r .aws_region.value tf_outputs.json) update-kubeconfig --name $(jq -r .eks_cluster_name.value tf_outputs.json)
    ```

2.  **Get ArgoCD Admin Password**:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

3.  **Access ArgoCD UI**:
    ```bash
    kubectl -n argocd port-forward svc/argocd-server 8080:443
    ```
    You can then access the UI at `https://localhost:8080` and log in with the username `admin` and the password you retrieved.

## GitOps Workflow

This project is designed to be managed via Git. After the initial Terraform deployment, you should not need to run `terraform apply` again unless you are changing the underlying AWS infrastructure.

### Adding a New Application

To deploy a new application to the EKS cluster:

1.  **Edit `k8s/argocd/values.yaml`**: Open this file and find the `deploymentWaves` section.
2.  **Add Application Definition**: Add your new application to the appropriate wave. For most applications, this will be `wave-1-applications`.

    **Example**: To add a new application from a different Git repository.

    ```yaml
      - name: wave-1-applications
        order: 1
        description: "Application deployments"
        namespaces:
          - test
          - production
        applications:
          - name: my-new-app          # A unique name for your app
            namespace: my-namespace    # The k8s namespace to deploy to
            project: my-project        # The ArgoCD project
            source:
              repoURL: 'https://github.com/my-org/my-app-repo.git'
              path: helm/           # Path to the chart or manifests
              targetRevision: main  # The branch or tag to track
    ```

    If your application is in the same repository, you can omit the `source` block and just use `path`.

3.  **Commit and Push**: Commit the changes to `k8s/argocd/values.yaml` and push them to your Git repository.

ArgoCD will detect the change and automatically deploy your new application.

### Adding a New ArgoCD Project

ArgoCD Projects are used to group applications and restrict what can be deployed and where. To add a new project:

1.  **Edit `k8s/argocd/values.yaml`**: Open this file and find the `argocdProjects` section.
2.  **Add Project Definition**: Add your new project definition.

    **Example**:

    ```yaml
    # ArgoCD Projects
    argocdProjects:
      - name: my-project
        description: "Project for my team"
        sourceRepos:
          - "https://github.com/my-org/*" # Restrict to repos in my-org
        destinations:
          - namespace: "my-namespace"
            server: "https://kubernetes.default.svc"
        clusterResourceWhitelist:
          - group: "*"
            kind: "*"
    ```

3.  **Commit and Push**: Commit the changes and push them to Git.

ArgoCD will create the new project, which you can then assign to your applications.

## Secrets Management with AWS Secrets Store CSI Driver

This project utilizes the AWS Secrets Store CSI Driver to securely inject secrets from AWS Secrets Manager directly into your Kubernetes pods as mounted volumes. This ensures that sensitive information is never stored in Git in plain text and is managed centrally in AWS.

### 1. Create Secret in AWS Secrets Manager

You can create secrets in AWS Secrets Manager using the AWS Console, CLI, or programmatically. For a GitOps approach, managing your secrets' metadata via Terraform is recommended.

**Example: Creating a Secret (Terraform)**

The `infrastructure/environments/main.tf` file includes an example of how to create a secret in AWS Secrets Manager:

```terraform
resource "random_string" "secret_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_secretsmanager_secret" "calculation_api_key" {
  name = "calculation-app/api-key-${random_string.secret_suffix.result}"
}

resource "aws_secretsmanager_secret_version" "calculation_api_key" {
  secret_id     = aws_secretsmanager_secret.calculation_api_key.id
  secret_string = "{\"api_key\": \"a-very-secret-api-key\"}" # Store as JSON
}
```

This example creates a secret named `calculation-app/api-key-<random_suffix>` with a JSON payload `{"api_key": "a-very-secret-api-key"}`.

### 2. Define `SecretProviderClass`

The `SecretProviderClass` tells the Secrets Store CSI Driver how to connect to AWS Secrets Manager and which secrets to fetch. This resource is managed by ArgoCD (defined in `k8s/business-apps-config/secrets/calculation-secret-provider-class.yaml`).

**Example: `k8s/business-apps-config/secrets/calculation-secret-provider-class.yaml`**

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: calculation-api-key-secrets
  namespace: business-apps # Target namespace for the SecretProviderClass
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "calculation-app/api-key" # Name of your secret in AWS Secrets Manager
        objectType: "secretsmanager"
        jmesPath:
          - path: api_key # Path within the JSON secret payload
            objectAlias: API_KEY # Alias for the secret key in the mounted volume
  secretObjects:
    - secretName: calculation-api-key-secret # The name of the Kubernetes Secret to create
      type: Opaque
      data:
        - objectName: API_KEY # The alias from objectAlias above
          key: API_KEY # The key in the created Kubernetes Secret
```

ArgoCD automatically deploys this `SecretProviderClass` to the `business-apps` namespace.

### 3. Consume Secret in Your Application Pod

To make the secret available to your application, you need to configure your pod (e.g., in a Deployment or StatefulSet) to:

1.  Reference the `SecretProviderClass` using the `secrets-store.csi.k8s.io` volume.
2.  Mount the volume into your container.

**Example: Pod Configuration**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calculation-app
  namespace: business-apps
spec:
  # ... (selector, replicas)
  template:
    # ... (metadata)
    spec:
      serviceAccountName: default # Ensure your pod's ServiceAccount has permissions via EKS Pod Identity
      containers:
        - name: calculation
          image: your-image:latest
          # ...
          volumeMounts:
            - name: secrets-store-inline
              mountPath: "/mnt/secrets-store" # Mount path for secrets
              readOnly: true
      volumes:
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "calculation-api-key-secrets" # Reference your SecretProviderClass
```

Inside your `calculation` container, the `API_KEY` will be available as a file at `/mnt/secrets-store/API_KEY`. You can then read this file to access the secret value.

## ConfigMap Management

This project manages Kubernetes ConfigMaps for application configuration via ArgoCD. Values for these ConfigMaps can be dynamically injected from Terraform.

### 1. Define ConfigMap Manifest

ConfigMaps are defined as standard Kubernetes YAML manifests. These manifests can leverage Helm templating to consume values passed from Terraform via the main ArgoCD chart.

**Example: `k8s/business-apps-config/calculation-configmap.yaml`**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: application-config
  namespace: business-apps
data:
  db-url: "jdbc:postgresql://{{ .Values.dbUrl }}:{{ .Values.dbPort }}/postgres"
```

In this example, the `db-url` is dynamically constructed using `dbUrl` and `dbPort` values that are passed from Terraform.

### 2. Consume ConfigMap in Your Application Pod

To make the ConfigMap data available to your application, you can mount it as a volume or expose its data as environment variables.

**Example: Pod Configuration (Environment Variables)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calculation-app
  namespace: business-apps
spec:
  # ... (selector, replicas)
  template:
    # ... (metadata)
    spec:
      containers:
        - name: calculation
          image: your-image:latest
          # ...
          env:
            - name: DATABASE_URL
              valueFrom:
                configMapKeyRef:
                  name: application-config # Name of your ConfigMap
                  key: db-url            # Key within the ConfigMap
```

Inside your `calculation` container, the `db-url` will be available as an environment variable named `DATABASE_URL`.

## Cleanup

To destroy all the infrastructure created by this project, run the following command:

```bash
cd infrastructure/environments
terraform destroy --var-file="dev/terraform.tfvars"
```