output "ecr_repository_url" {
  description = "URL of the Project 4 ECR repository"
  value       = aws_ecr_repository.project4_app.repository_url
}