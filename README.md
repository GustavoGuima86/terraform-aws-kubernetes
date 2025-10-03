# AWS Infrastructure as Code with Terraform

This repository contains Terraform configurations for deploying a complete AWS infrastructure, primarily focused on running containerized applications with EKS (Elastic Kubernetes Service) and supporting services.

## Infrastructure Components

### Core Infrastructure
- **VPC**: Multi-AZ Virtual Private Cloud setup with public, private, and intra subnets
- **EKS Cluster**: Managed Kubernetes cluster with the following features:
  - Karpenter for automatic node provisioning
  - ArgoCD for GitOps deployments
  - Helm-based deployments

### Container Infrastructure
- **ECR**: Private container registry for storing Docker images
- **EBS CSI Driver**: For persistent volume management in EKS

### Database
- **RDS**: Managed relational database service with:
  - Parameter group configurations
  - CloudWatch integration
  - Security group management
  - SSM Parameter Store integration

### Observability Stack
- **Grafana**: Visualization and monitoring
- **Prometheus**: Metrics collection
- **Loki**: Log aggregation
- **Promtail**: Log collection agent

### Security & Management
- **AWS Secrets Manager**: For secure secrets management
- **SSM Parameter Store**: For configuration management
- **Security Groups**: Network security rules
- **IAM Roles and Policies**: Proper access control

## Project Structure
```
environments/         # Environment-specific configurations
├── dev/             # Development environment
└── ...              # Other environments
modules/             # Reusable Terraform modules
├── aws-rds/         # RDS database setup
├── aws-ssm-generic/ # SSM parameter store
├── ebs-csi-driver/  # EKS storage driver
├── ecr_repo/        # Container registry
├── eks/             # Kubernetes cluster and addons
└── vpc/             # Network infrastructure
```

## Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- kubectl (for Kubernetes operations)

## Usage

### Initial Setup
1. Navigate to the appropriate environment directory
2. Initialize Terraform:
```bash
terraform init
```

### Deployment
1. Plan your changes:
```bash
terraform plan --var-file="dev/terraform.tfvars"
```

2. Apply the changes:
```bash
terraform apply --var-file="dev/terraform.tfvars"
```

### Maintenance
- Format Terraform files:
```bash
terraform fmt -recursive
```

### Cleanup
To destroy the infrastructure:
```bash
terraform destroy --var-file="dev/terraform.tfvars"
```

### Connecting to EKS
Update your kubeconfig to connect to the EKS cluster:
```bash
aws eks --region eu-central-1 update-kubeconfig --name gustavo
```

## Future Enhancements
- [ ] Access Control Lists (ACL)
- [ ] Web Application Firewall (WAF)
- [ ] Additional environment configurations
