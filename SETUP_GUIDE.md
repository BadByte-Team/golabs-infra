# 🚀 GoLabs — Guía de Setup Completa

## Repos necesarios: 3

| # | Repo | Org/User | Contenido |
|---|------|----------|-----------|
| 1 | **golabs-api** | BadByte-Team | Go API, Dockerfile, `.env` |
| 2 | **golabs-ui** | BadByte-Team | Vue 3 + Vuetify, Dockerfile |
| 3 | **golabs-infra** | BadByte-Team | K8s manifests, ArgoCD apps, Kustomize overlays |

> [!NOTE]
> Opcionalmente puedes tener un 4to repo **golabs-pj** como monorepo que contenga api + ui + Jenkinsfile.
> En ese caso serían **2 repos**: `golabs-pj` (app) + `golabs-infra` (infra).

---

## Paso 1 — Crear los repos en GitHub

```bash
# Desde la org BadByte-Team en GitHub, crear:
# 1. BadByte-Team/golabs-pj     (o golabs-api + golabs-ui por separado)
# 2. BadByte-Team/golabs-infra
```

---

## Paso 2 — Subir golabs-pj (API + UI + Jenkinsfile)

```bash
cd ~/UTTT/Proyectos/golabs-pj

# Si ya tiene .git, solo agregar remote:
git remote add origin https://github.com/BadByte-Team/golabs-pj.git

# Si NO tiene .git:
git init
git remote add origin https://github.com/BadByte-Team/golabs-pj.git

git add golabs-api/ golabs-ui/ Jenkinsfile
git commit -m "feat: initial project — API + UI + Jenkinsfile"
git branch -M main
git push -u origin main
```

Estructura resultante en el repo:

```
golabs-pj/
├── Jenkinsfile
├── golabs-api/
│   ├── Dockerfile
│   ├── go.mod
│   ├── cmd/
│   ├── internal/
│   └── ...
└── golabs-ui/
    ├── Dockerfile
    └── ui/
        ├── package.json
        ├── src/
        └── ...
```

---

## Paso 3 — Subir golabs-infra (K8s + ArgoCD)

```bash
cd ~/UTTT/Proyectos/golabs-pj/golabs-infra

git init
git remote add origin https://github.com/BadByte-Team/golabs-infra.git
git add .
git commit -m "feat: initial k8s manifests + argocd apps"
git branch -M main
git push -u origin main
```

Estructura resultante en el repo:

```
golabs-infra/
├── README.md
├── argocd/
│   ├── project.yaml            # AppProject
│   └── application-dev.yaml    # Application (auto-sync)
└── k8s/
    ├── base/
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── ingress.yaml        # Traefik (k3s)
    │   ├── api/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── hpa.yaml
    │   │   └── secret.yaml     # ⚠️ actualizar valores
    │   ├── ui/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   └── configmap-nginx.yaml
    │   └── db/
    │       ├── statefulset.yaml
    │       ├── service.yaml
    │       └── secret.yaml     # ⚠️ actualizar valores
    └── overlays/
        ├── dev/                # 1 réplica, tag "dev"
        └── prod/               # 2 réplicas, tag "latest"
```

---

## Paso 4 — Actualizar Secrets (ANTES de deployar)

```bash
# Generar valores base64:
echo -n 'tu_password_real' | base64
echo -n 'tu_jwt_secret_real' | base64

# Editar los secrets:
# k8s/base/api/secret.yaml  → DB_USER, DB_PASSWORD, JWT_SECRET, ALLOWED_ORIGINS
# k8s/base/db/secret.yaml   → MARIADB_ROOT_PASSWORD, MARIADB_USER, MARIADB_PASSWORD
```

> [!CAUTION]
> **NO commitear secrets reales a Git.** En producción, usar Sealed Secrets, External Secrets Operator, o AWS Secrets Manager.

---

## Paso 5 — Instalar ArgoCD en k3s (EC2)

```bash
# Conectarse al EC2
ssh -i tu-key.pem ubuntu@<EC2_IP>

# Crear namespace y aplicar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que los pods estén ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# Obtener password inicial del admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # nueva línea

# Exponer ArgoCD (opción 1: NodePort para acceder desde el browser)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Ver en qué puerto quedó:
kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}'
# Acceder en: http://<EC2_IP>:<NODE_PORT>

# Opción 2: Port forward (si prefieres no exponer)
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 0.0.0.0 &
# Acceder en: https://<EC2_IP>:8443
```

> [!IMPORTANT]
> Asegurar que el Security Group del EC2 tenga abierto el puerto de ArgoCD (NodePort o 8443).

---

## Paso 6 — Conectar ArgoCD al repo golabs-infra

### Opción A: Desde la UI de ArgoCD

1. Ir a **Settings → Repositories → Connect Repo**
2. Method: **HTTPS**
3. URL: `https://github.com/BadByte-Team/golabs-infra.git`
4. Si el repo es privado, agregar un GitHub Personal Access Token como password

### Opción B: Desde CLI

```bash
# Instalar argocd CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Login
argocd login <ARGOCD_IP>:<PORT> --username admin --password <PASSWORD> --insecure

# Agregar repo (si es privado)
argocd repo add https://github.com/BadByte-Team/golabs-infra.git \
    --username GutsNet \
    --password <GITHUB_TOKEN>
```

---

## Paso 7 — Deployar la aplicación con ArgoCD

```bash
# Aplicar el AppProject
kubectl apply -f argocd/project.yaml

# Aplicar la Application (esto inicia el sync automático)
kubectl apply -f argocd/application-dev.yaml

# Verificar estado
argocd app get golabs-dev

# O desde kubectl:
kubectl get all -n golabs
```

Después de aplicar, ArgoCD:

1. ✅ Lee `k8s/overlays/dev/` del repo
2. ✅ Crea el namespace `golabs`
3. ✅ Deploya API, UI, DB, Ingress
4. ✅ Auto-sync habilitado (cualquier push al repo = deploy automático)

---

## Paso 8 — Configurar Jenkins

### Credenciales necesarias en Jenkins

| ID | Tipo | Descripción |
|----|------|-------------|
| `dockerhub-id` | Username/Password | Docker Hub (gjisus/\*) |
| `github-token-id` | Username/Password | GitHub PAT para push a golabs-infra |
| `sonarqube-server` | SonarQube server | Configuración global de SonarQube |

### Crear pipeline en Jenkins

1. **New Item → Pipeline**
2. **Pipeline → Definition:** Pipeline script from SCM
3. **SCM:** Git
4. **Repository URL:** `https://github.com/BadByte-Team/golabs-pj.git`
5. **Script Path:** `Jenkinsfile`
6. **Branch:** `*/main`

---

## Paso 9 — Verificar el flujo completo

```bash
# 1. Hacer un cambio en golabs-api o golabs-ui
# 2. Push a main → Jenkins se dispara
# 3. Jenkins: build → push Docker Hub → update golabs-infra
# 4. ArgoCD detecta el cambio → sync al clúster

# Verificar pods:
kubectl get pods -n golabs

# Verificar ingress:
kubectl get ingress -n golabs

# Acceder a la app:
curl http://<EC2_IP>/
curl http://<EC2_IP>/api/healthz/ready
```

---

## Diagrama del flujo

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐     ┌─────────┐
│  Developer   │────→│   GitHub     │────→│   Jenkins    │────→│ Docker  │
│  git push    │     │  golabs-pj   │     │  CI Pipeline │     │   Hub   │
└─────────────┘     └─────────────┘     └──────┬───────┘     └─────────┘
                                               │
                                               │ git push (sed image tag)
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
