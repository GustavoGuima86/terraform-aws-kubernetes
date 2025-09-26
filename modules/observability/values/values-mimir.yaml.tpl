mimir:
  structuredConfig:
    alertmanager_storage:
      s3:
        bucket_name: ${bucket_alert}
        endpoint: s3.${region}.amazonaws.com
        insecure: true
    usage_stats:
      enabled: false
      installation_mode: helm
    blocks_storage:
      backend: s3
      bucket_store:
        sync_dir: /data/tsdb-sync
      s3:
        bucket_name: ${bucket_chunk}
        endpoint: s3.${region}.amazonaws.com
        insecure: true
      tsdb:
        dir: /data/tsdb
    compactor:
      data_dir: /data
    multitenancy_enabled: false
    ingester:
      instance_limits:
        max_ingestion_rate: 0
      ring:
        final_sleep: 0s
        num_tokens: 512
    ingester_client:
      grpc_client_config:
        max_recv_msg_size: 104857600
        max_send_msg_size: 104857600
    server:
      log_level: debug
      grpc_server_max_concurrent_streams: 1000
      grpc_server_max_recv_msg_size: 104857600
      grpc_server_max_send_msg_size: 104857600
    limits:
      ingestion_rate: 800000
      max_global_series_per_metric: 0
      max_global_series_per_user: 0
      max_label_names_per_series: 80
    memberlist:
      abort_if_cluster_join_fails: false
      compression_enabled: false
    ruler:
      alertmanager_url: dnssrvnoa+http://_http-metrics._tcp.{{ template "mimir.fullname"
        . }}-alertmanager-headless.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain
        }}/alertmanager
      enable_api: true
      rule_path: /data
    ruler_storage:
      s3:
        bucket_name: ${bucket_ruler}
        endpoint: s3.${region}.amazonaws.com
        insecure: true
    runtime_config:
      file: /var/{{ include "mimir.name" . }}/runtime.yaml

minio:
  enabled: false
querier:
  replicas: 2

nginx:
  enabled: true
  replicas: 2

serviceAccount:
  create: true
  name: ${sa_mimir_name}
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}
metaMonitoring:
  serviceMonitor:
    enabled: true
    labels:
      release: ${kube_prometheus}