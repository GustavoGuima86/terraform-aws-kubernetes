grafana:
  adminPassword: ${adminPassword}
  additionalDataSources:
    - name: Loki
      type: loki
      isDefault: false
      editable: true
      access: proxy
      url: http://loki:3100
      jsonData:
        timeout: 60
        maxLines: 1000
      version: 1
    - name: Prometheus
      type: prometheus
      isDefault: false
      editable: true
      access: proxy
      url: http://${mimir}-nginx.${namespace}.svc:80/prometheus
      jsonData:
        timeout: 60
        maxLines: 1000
      version: 1
prometheus:
  prometheusSpec:
    remoteWrite:
    - url:  http://${mimir}-nginx.${namespace}.svc:80/api/v1/push
    externalLabels:
       environment: mimir
    nodeSelector: { }
    affinity: { }