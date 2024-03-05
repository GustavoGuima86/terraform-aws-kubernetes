provider "aws" {
  region = var.targetRegion

  # assume_role {
  #  role_arn     = var.deploymentRoleARN
  #  session_name = "TF_EKS_DEPLOY"
  # }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"

  # assume_role {
  #  role_arn     = var.deploymentRoleARN
  #  session_name = "TF_EKS_DEPLOY"
  # }
}

provider "aws" {
  alias  = "eks-aws"
  region = "eu-central-1"

}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.cluster_name, /*"--role", var.deploymentRoleARN*/]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.cluster_name, /*"--role", var.deploymentRoleARN*/]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.cluster_name, /*"--role", var.deploymentRoleARN*/]
  }
}
