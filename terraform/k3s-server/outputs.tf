output "server_public_ip" {
  description = "IP pública del servidor K3s"
  value       = aws_instance.k3s_server.public_ip
}

output "server_public_dns" {
  description = "DNS público del servidor K3s"
  value       = aws_instance.k3s_server.public_dns
}

output "ssh_command" {
  description = "Comando para conectarse por SSH"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.k3s_server.public_ip}"
}

output "argocd_url" {
  description = "URL de ArgoCD"
  value       = "http://${aws_instance.k3s_server.public_ip}:30080"
}

output "app_url" {
  description = "URL de la aplicación GoLabs"
  value       = "http://${aws_instance.k3s_server.public_ip}"
}

output "argocd_password_command" {
  description = "Comando para obtener la contraseña de ArgoCD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
