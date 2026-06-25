# golabs-infra

Repositorio de infraestructura GitOps para la plataforma **GoLabs**.  
ArgoCD monitorea este repo y sincroniza automáticamente los cambios al clúster k3s.

## Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐     ┌─────────┐
│  Developer   │────→│   GitHub     │────→│   Jenkins    │────→│ Docker  │
│  git push    │     │  golabs-pj   │     │  CI Pipeline │     │   Hub   │
└─────────────┘     └─────────────┘     └──────┬───────┘     └─────────┘
                                               │
                                               │ git push (update image tag)
                                               ▼
                                        ┌──────────────┐
                                        │   GitHub      │
                                        │ golabs-infra  │
                                        └──────┬───────┘
                                               │
                                               │ auto-sync
                                               ▼
                                        ┌──────────────┐     ┌─────────┐
                                        │   ArgoCD     │────→│  k3s    │
                                        │  (watcher)   │     │  EC2    │
                                        └──────────────┘     └─────────┘
```

## Estructura del repositorio

```
golabs-infra/
│
├── terraform/
│   ├── backend/                 # S3 + DynamoDB (state remoto de Terraform)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── k3s-server/              # EC2 t3.micro + Security Group + K3s auto-install
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── k8s/
│   ├── base/                    # Manifiestos base (Kustomize)
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── ingress.yaml         # Traefik Ingress (k3s default)
│   │   ├── api/                 # Go API
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── hpa.yaml
│   │   │   └── secret.yaml      # ⚠️ actualizar valores
│   │   ├── ui/                  # Vue 3 + Vuetify (Nginx)
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── configmap-nginx.yaml
│   │   └── db/                  # MariaDB
│   │       ├── statefulset.yaml
│   │       ├── service.yaml
│   │       └── secret.yaml      # ⚠️ actualizar valores
│   └── overlays/
│       ├── dev/                 # 1 réplica, tag auto-updated por Jenkins
│       └── prod/                # 2 réplicas, tag auto-updated por Jenkins
│
├── argocd/
│   ├── project.yaml             # AppProject "golabs"
│   ├── application-dev.yaml     # Application → k8s/overlays/dev
│   └── application-prod.yaml    # Application → k8s/overlays/prod
│
├── docker/
│   ├── api/
│   │   └── Dockerfile           # Go multi-stage build
│   └── ui/
│       ├── Dockerfile           # Vue build + Nginx serve
│       └── nginx.conf           # Config default para standalone
│
├── ci/
│   └── Jenkinsfile              # Pipeline: lint → test → build → push → update infra
│
├── .gitignore
└── README.md
```

## Flujo GitOps

```
Jenkins (golabs-pj)           Este repo (golabs-infra)         ArgoCD → k3s
───────────────────           ────────────────────────         ─────────────
1. Build & Push Docker   →   2. sed actualiza image tag   →   3. Sync automático
   gutsnet/golabs-api:TAG          en kustomization.yaml           al clúster
   gutsnet/golabs-ui:TAG
```

## Quick Start

```bash
# 1. Crear backend de Terraform (solo una vez)
cd terraform/backend
terraform init && terraform apply -auto-approve

# 2. Crear EC2 con K3s + ArgoCD
cd ../k3s-server
terraform init
terraform apply -var="key_name=aws-key"

# 3. Aplicar ArgoCD
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application-dev.yaml
```

## ⚠️ Antes de usar

1. Actualizar Secrets en `k8s/base/api/secret.yaml` y `k8s/base/db/secret.yaml`
2. Verificar que ArgoCD esté instalado en el namespace `argocd`
3. El Jenkinsfile en `golabs-pj` ya apunta a este repo
4. En producción: usar Sealed Secrets o External Secrets en lugar de secrets planos
