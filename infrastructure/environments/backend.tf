# Terraform S3 Backend Configuration
# This file contains the backend configuration for remote state storage
# Replace YOUR_TERRAFORM_STATE_BUCKET_NAME with your actual bucket name from CloudFormation stack output

terraform {
  backend "s3" {
    bucket = "YOUR_TERRAFORM_STATE_BUCKET_NAME"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    
    # Enable server-side encryption
    encrypt = true
    
    # Use S3 native locking (no DynamoDB required)
    # S3 supports native state locking since Terraform 1.6+
    use_lockfile = true
  }
}
