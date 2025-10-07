module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.3.1"

  cluster_name                    = module.eks.cluster_name
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.cluster_name
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  }
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "kube-system"
  create_namespace = false

  chart      = "karpenter"
  version    = "1.7.1"
  repository = "oci://public.ecr.aws/karpenter"

  values = [
    yamlencode({
      nodeSelector = {
        "karpenter.sh/controller" = "true"
      }
      settings = {
        clusterEndpoint   = module.eks.cluster_endpoint
        clusterName       = module.eks.cluster_name
        interruptionQueue = module.karpenter.queue_name
      }
      webhook = {
        enabled = false
      }
    })
  ]

  depends_on = [
    module.eks
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body  = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: gutonodeclass
spec:
  role: ${module.eks.cluster_name}
  amiSelectorTerms:
    - alias: "al2023@v20250519"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  tags:
    karpenter.sh/discovery: ${module.eks.cluster_name}
YAML
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body  = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gutonodepool
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: gutonodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: [ "arm64" ]
        - key: kubernetes.io/os
          operator: In
          values: [ "linux" ]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m"]
        - key: karpenter.k8s.aws/instance-family
          operator: NotIn
          values: [ "m3" ]
        - key: karpenter.sh/capacity-type
          operator: In
          values: [ "spot" ]
  limits:
    cpu: 100
    weight: 10
  # disruption:
  #   consolidationPolicy: WhenEmptyOrUnderutilized
  #   consolidateAfter: 300s
  #   budgets:
  #     - nodes: "10%"
  #     - nodes: "0"
  #       schedule: "0 8 * * *" # Start of the period to this rule be applied
  #       duration: 12h # the period this rule will be active
  #       reasons: # Reasons to the rule be applied
  #         - "Underutilized"
  #         - "Drifted"
  #         - "Empty"
YAML
  depends_on = [helm_release.karpenter]
}

locals {
  region = data.aws_region.current.id
}
