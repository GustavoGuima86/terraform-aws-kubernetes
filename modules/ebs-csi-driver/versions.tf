terraform {
  required_version = ">= 1.4.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34.0"
    }
  }
}