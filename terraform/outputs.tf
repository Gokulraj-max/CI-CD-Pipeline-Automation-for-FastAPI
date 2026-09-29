output "instance_public_ip" {
  description = "Public IP address of the EC2 CI/CD server"
  value       = aws_instance.cicd_server.public_ip
}

output "jenkins_url" {
  description = "URL for accessing Jenkins"
  value       = "http://${aws_instance.cicd_server.public_ip}:8080"
}

output "fastapi_url" {
  description = "URL for accessing FastAPI application"
  value       = "http://${aws_instance.cicd_server.public_ip}:8001"
}
