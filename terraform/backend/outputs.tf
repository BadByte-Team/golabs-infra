output "bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = aws_dynamodb_table.terraform_locks.name
}
