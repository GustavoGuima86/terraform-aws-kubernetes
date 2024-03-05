resource "kubectl_manifest" "storageclass_gp3_secure" {
  yaml_body = <<-YAML
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
        name: gp3-secure
        annotations:
            storageclass.kubernetes.io/is-default-class: "true"
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    parameters:
        encrypted: "true"
        fsType: ext4
        type: gp3
  YAML

  depends_on = [
    helm_release.ebs_csi_driver
  ]
}