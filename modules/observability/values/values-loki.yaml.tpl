loki:
  auth_enabled: false
  schemaConfig:
     configs:
       - from: "2024-04-01"
         store: tsdb
         object_store: s3
         schema: v13
         index:
           prefix: loki_index_
           period: 24h

  storage_config:
     aws:
       region: ${region}
       bucketnames: ${bucket_chunk}
       s3forcepathstyle: false
  ingester:
     chunk_encoding: snappy
  pattern_ingester:
     enabled: true

  storage:
      type: s3
      bucketNames:
        chunks: ${bucket_chunk}
        ruler: ${bucket_ruler}
      s3:
        region: ${region}
        #insecure: true
      # s3forcepathstyle: false
serviceAccount:
  create: true
  name: ${sa_loki_name}
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}

deploymentMode: SingleBinary

singleBinary:
  replicas: 2

# Zero out replica counts of other deployment modes
backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0

ingester:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
distributor:
  replicas: 0
compactor:
  replicas: 0
indexGateway:
  replicas: 0
bloomCompactor:
  replicas: 0
bloomGateway:
  replicas: 0