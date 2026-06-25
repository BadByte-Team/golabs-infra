# ──────────────────────────────────────────────────────
# EC2 K3s Server — Servidor de producción para GoLabs
# Crea un Security Group y una instancia EC2 donde
# corre K3s + ArgoCD + la aplicación GoLabs.
# ──────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto — requiere haber ejecutado terraform/backend/ primero
  backend "s3" {
    bucket         = "golabs-terraform-state-redwings-ctf-1"
    key            = "k3s-server/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "golabs-terraform-locks-redwings-ctf-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

# ── Security Group ──
resource "aws_security_group" "k3s_sg" {
  name        = "golabs-k3s-sg"
  description = "Security Group para el servidor K3s de GoLabs"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # K3s API Server
  ingress {
    description = "K3s API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # HTTP (Traefik Ingress)
  ingress {
    description = "HTTP — Traefik Ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Traefik Ingress)
  ingress {
    description = "HTTPS — Traefik Ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD UI (NodePort)
  ingress {
    description = "ArgoCD UI"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # App NodePort fallback
  ingress {
    description = "App NodePort fallback"
    from_port   = 30081
    to_port     = 30081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Static HTML site (NodePort)
  ingress {
    description = "Static HTML site"
    from_port   = 30082
    to_port     = 30082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins webhook callback (si Jenkins está externo)
  ingress {
    description = "Jenkins webhook"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "golabs-k3s-sg"
    Project     = "golabs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ── EC2 Instance ──
resource "aws_instance" "k3s_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # User data: instala K3s + configura swap automáticamente
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # ── Swap de 2GB (crítico para m7i-flex.large con 1GB RAM) ──
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' >> /etc/sysctl.conf

    # ── Instalar K3s ──
    curl -sfL https://get.k3s.io | sh -

    # ── Configurar kubectl para ubuntu user ──
    mkdir -p /home/ubuntu/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown -R ubuntu:ubuntu /home/ubuntu/.kube
    sed -i 's/default/golabs-k3s/g' /home/ubuntu/.kube/config

    # ── Instalar ArgoCD ──
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Esperar a que K3s esté listo
    until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
      sleep 5
    done

    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Exponer ArgoCD en NodePort 30080
    sleep 60 # esperar a que los pods de ArgoCD se creen
    kubectl patch svc argocd-server -n argocd \
      -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30080}]}}'

    echo "✅ K3s + ArgoCD instalados correctamente" > /home/ubuntu/setup-complete.txt
    chown ubuntu:ubuntu /home/ubuntu/setup-complete.txt
  EOF

  tags = {
    Name        = "golabs-k3s-server"
    Project     = "golabs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
