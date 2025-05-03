// AWS Elastic Container Registry (ECR) Definition ---------------------------------------------------------------------

resource "aws_ecr_repository" "example" {
  name                 = "hello-world"

  image_scanning_configuration {
    scan_on_push = true  # Enable image scanning on push
  }

  tags = {
    "Environment" = "Development"
    "Project"     = "Terraform"
  }
}

output "ecr_repository_uri" {
  value = aws_ecr_repository.example.repository_url
}