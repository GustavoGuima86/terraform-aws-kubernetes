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
- Observability (Grafana + Prometheus + loki)



## Deploy using 

```terraform plan --var-file="dev/terraform.tfvars"```

```terraform apply --var-file="dev/terraform.tfvars"```

## Lint

`terraform fmt -recursive`

## Destroy using 

```terraform destroy -target module.eks --var-file="prod/terraform.tfvars"```

```terraform destroy --var-file="prod/terraform.tfvars"```


## Update eks config locally

`aws eks --region eu-central-1 update-kubeconfig --name gustavo-cluster`

## Get initial ArgoCD password 

user: admin
password: `kubectl -n test get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`


