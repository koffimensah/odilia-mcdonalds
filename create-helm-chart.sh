#!/bin/bash

echo "Creating Helm chart structure for Odilia..."

# Create directories
mkdir -p helm/odilia/templates

# Create Chart.yaml
cat > helm/odilia/Chart.yaml << 'EOF'
apiVersion: v2
name: odilia
description: Highly available voting application for McDonald's
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - voting
  - redis
  - postgresql
  - high-availability
maintainers:
  - name: McDonalds DevOps Team
    email: devops@mcdonalds.com
EOF

# Create values.yaml
cat > helm/odilia/values.yaml << 'EOF'
# Global settings
global:
  namespace: odilia-mcdonalds
  imagePullPolicy: IfNotPresent
  storageClass: standard

# Redis configuration
redis:
  password: "change-me-in-production"
  master:
    replicas: 1
  replica:
    replicas: 2
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  persistence:
    enabled: true
    size: 1Gi

# Sentinel configuration
sentinel:
  replicas: 3
  config:
    quorum: 2
    downAfterMilliseconds: 5000
    failoverTimeout: 60000
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi

# PostgreSQL configuration
postgres:
  database: yelbdatabase
  user: postgres
  password: "change-me-in-production"
  master:
    replicas: 1
  replica:
    replicas: 3
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
  persistence:
    enabled: true
    size: 5Gi

# Application server configuration
appserver:
  replicas: 2
  image:
    repository: mreferre/yelb-appserver
    tag: "0.5"
  service:
    type: ClusterIP
    port: 4567
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# Frontend configuration
frontend:
  replicas: 2
  image:
    repository: mreferre/yelb-ui
    tag: "0.7"
  service:
    type: LoadBalancer
    port: 80
    nodePort: 30080
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi

# Ingress configuration
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: odilia.local
      paths:
        - path: /
          pathType: Prefix
EOF

echo "âœ… Helm chart structure created!"
echo "í³‚ Location: helm/odilia/"
echo ""
echo "Next steps:"
echo "1. Review values.yaml and update passwords"
echo "2. Generate Kubernetes manifests"
echo "3. Deploy to Minikube"

