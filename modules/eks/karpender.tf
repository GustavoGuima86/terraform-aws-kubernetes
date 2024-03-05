################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.21.0"

  cluster_name                    = module.eks.cluster_name
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  enable_karpenter_instance_profile_creation = true

  create_instance_profile = true

  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
}


resource "helm_release" "karpenter_crd" {
  depends_on       = [module.eks]
  namespace        = "karpenter"
  create_namespace = true

  name         = "karpenter-crd"
  repository   = "oci://public.ecr.aws/karpenter"
  chart        = "karpenter-crd"
  version      = "v0.32.1"
  replace      = true
  force_update = true

}

resource "helm_release" "karpenter" {
  depends_on       = [module.eks, helm_release.karpenter_crd]
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.32.1"
  replace    = true

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }

  set {
    name  = "settings.featureGates.drift"
    value = "True"
  }

  set {
    name  = "tolerations[0].key"
    value = "system"
  }

  set {
    name  = "tolerations[0].value"
    value = "owned"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  #  set {
  #    name  = "serviceMonitor.enabled"
  #    value = "true"
  #  }
}

resource "kubectl_manifest" "karpenter_spot_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: spot
    spec:
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 72h
      limits:
        cpu: 100
        memory: 200Gi
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: karpenter.k8s.aws/instance-size
              operator: NotIn
              values: [nano, micro, small]
          taints:
          - key: spot
            value: "true"
            effect: NoSchedule

YAML
  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_on_demand_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: on-demand
    spec:
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 300s
        expireAfter: 72h
      limits:
        cpu: 100
        memory: 200Gi
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: karpenter.k8s.aws/instance-size
              operator: NotIn
              values: [nano, micro, small, medium]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["c6a", "c6g", "c7g", "t3a", "t3", "t2"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["2","4","8"]
          taints:
          - key: on-demand
            value: "true"
            effect: NoSchedule
YAML
  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_on_demand_monitoring_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: monitoring
    spec:
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 1440h
      limits:
        cpu: 100
        memory: 200Gi
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["c6a", "t3a"]
          taints:
          - key: monitoring
            value: "true"
            effect: NoSchedule
YAML
  depends_on = [
    helm_release.karpenter
  ]
}

#
# Node Class
#

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.role_name}
      detailedMonitoring: true
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2
        httpTokens: required
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 40Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}