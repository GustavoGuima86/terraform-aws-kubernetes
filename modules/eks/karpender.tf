module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.36.0"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true

  enable_irsa                     = true
  create_pod_identity_association = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = [
    "karpenter:karpenter"
  ]

  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "karpenter-${module.eks.cluster_iam_role_name}"
}

resource "aws_iam_policy" "karpenter_policy" {
  name        = "KarpenterPolicy"
  description = "Policy to allow EKS nodes to interact with Karpenter dependencies"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVpcs",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "iam:AddRoleToInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:PassRole",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "pricing:GetProducts",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "ssm:GetParameter",
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_karpenter" {
  role       = module.karpenter.iam_role_name
  policy_arn = aws_iam_policy.karpenter_policy.arn
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace = "karpenter"
  create_namespace = true

  chart   = "karpenter"
  version = "1.5.0"
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
      tolerations = [
        {
          key      = "karpenter.sh/controller"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]
      webhook = {
        enabled = false
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = module.karpenter.iam_role_arn
        }
      }
    })
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: gutonodeclass
  namespace: karpenter
spec:
  role: ${ module.karpenter.node_iam_role_arn }
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
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gutonodepool
  namespace: karpenter
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
          values: [ "amd64" ]
        - key: kubernetes.io/os
          operator: In
          values: [ "linux" ]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: [ "c", "m", "r", "n" ]
        - key: karpenter.k8s.aws/instance-family
          operator: NotIn
          values: [ "m3" ]
        - key: karpenter.sh/capacity-type
          operator: In
          values: [ "on-demand" ]
  limits:
    cpu: 1000
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