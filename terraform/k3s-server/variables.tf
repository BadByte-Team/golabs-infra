variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI de Ubuntu 22.04 LTS (us-east-1)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro" # Free tier eligible
}

variable "key_name" {
  description = "Nombre del Key Pair SSH en AWS"
  type        = string
  # Sin default — obligatorio pasar con -var="key_name=aws-key"
}

variable "allowed_cidr" {
  description = "CIDR permitido para SSH, K3s API y ArgoCD (tu IP pública)"
  type        = string
  default     = "0.0.0.0/0" # ⚠️ En producción, restringir a tu IP: "x.x.x.x/32"
}
