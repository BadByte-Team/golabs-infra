variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para el state de Terraform (debe ser globalmente único)"
  type        = string
  default     = "golabs-terraform-state-redwings-ctf-1"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el locking del state"
  type        = string
  default     = "golabs-terraform-locks-redwings-ctf-1"
}
