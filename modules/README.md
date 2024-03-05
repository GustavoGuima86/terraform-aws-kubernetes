# IAC Terraform 

Terraform for
- EKS(helm, carpenter)
- ALB
- RDS
- Security group
- ACL (to do)
- WAF (to do)
- VPC
- ECR private repo



## Deploy using 

```terraform plan --var-file="dev/terraform.tfvars"```

```terraform apply --var-file="dev/terraform.tfvars"```

## Lint

`terraform fmt -recursive`

## Destroy using 

```terraform destroy --var-file="prod/terraform.tfvars"```



## Update eks config locally

`aws eks --region eu-central-1 update-kubeconfig --name test`




