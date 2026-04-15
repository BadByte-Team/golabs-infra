# golabs-infra

Repositorio de infraestructura GitOps para la plataforma **GoLabs**.  
ArgoCD monitorea este repo y sincroniza automáticamente los cambios al clúster k3s.

## Estructura

```
├── argocd/
│   ├── project.yaml           # AppProject "golabs"
│   └── application-dev.yaml   # Application → k8s/overlays/dev
├── k8s/
│   ├── base/                  # Manifiestos base (Kustomize)
│   │   ├── api/               # Deployment, Service, HPA, Secret
│   │   ├── ui/                # Deployment, Service, ConfigMap (nginx)
│   │   ├── db/                # StatefulSet MariaDB, Service, Secret
│   │   ├── ingress.yaml       # Traefik Ingress (k3s)
│   │   └── namespace.yaml
│   └── overlays/
│       ├── dev/               # 1 réplica, tag "dev"
│       └── prod/              # 2 réplicas, tag "latest"
```

## Flujo GitOps

```
Jenkins (golabs-pj)           Este repo (golabs-infra)         ArgoCD → k3s
───────────────────           ────────────────────────         ─────────────
1. Build & Push Docker   →   2. sed actualiza image tag   →   3. Sync automático
   gjisus/golabs-api:TAG          en deployment.yaml               al clúster
   gjisus/golabs-ui:TAG
```

## Deploy manual

```bash
# Aplicar overlay dev
kubectl apply -k k8s/overlays/dev/

# Aplicar overlay prod
kubectl apply -k k8s/overlays/prod/

# Instalar ArgoCD app
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application-dev.yaml
```

## ⚠️ Antes de usar

1. Actualizar Secrets en `k8s/base/api/secret.yaml` y `k8s/base/db/secret.yaml`
2. Verificar que ArgoCD esté instalado en el namespace `argocd`
3. El Jenkinsfile en `golabs-pj` ya apunta a este repo
