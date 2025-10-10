module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true

}

resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "gp3-secure"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete" # Or "Retain" if you want to keep the EBS volume after PVC is deleted
  parameters = {
    type   = "gp3" # General Purpose SSD (gp3) volume type. You can also use gp2, io1, io2, etc.
    fsType = "ext4"
  }
}