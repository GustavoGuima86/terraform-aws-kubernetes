cluster_name                      = "test"
enable_eks_karpenter_rollout      = true
enable_aws_alb_controller_rollout = true
targetRegion                      = "eu-central-1"
vpc_cidr                          = "10.0.0.0/16"
vpc_name                          = "eks-vpc"
eks_version                       = "1.33"
namespaces                        = "test"
namespace_labeling                = "test"
auth_role_sso                     = "test"
service_name                      = "calculation"
database_configurations = {
  db_name        = "testdb"
  engine         = "postgres"
  port           = 5432
  instance_class = "db.t3.medium"
  storage = {
    type       = "gp3"
    iops       = 3000
    throughput = 125
    size       = 20
  }
  DANGEROUS_disable_deletion_protection = false
  DANGEROUS_skip_final_snapshot         = true
  master_username                       = "test_user"
  performance_insights                  = true

  # The logs export change for each engine
  # postgres: ["postgresql", "upgrade"]
  # mysql: ["audit", "error", "general", "slowquery"]
  # MSSQL: ["agent" , "error"]
  # Oracle: ["alert", "audit", "listener", "trace"]
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 5
  backup_retention_period         = 30
  backup_window                   = "03:00-04:00"
  maintenance_window              = "sun:05:00-sun:06:00"
  apply_immediately               = true
  parameter_group_configs = {
    family = "postgres16"
    name   = "test-pg"
  }
  multi_az            = false
  publicly_accessible = false
}