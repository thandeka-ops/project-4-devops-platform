resource "aws_ecr_repository" "project4_app" {
  name                 = "project4-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}