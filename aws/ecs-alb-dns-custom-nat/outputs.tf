# ACM Certificate ARN
output "certificate_arn" {
  value = aws_acm_certificate.example.arn
}

# ECS Cluster Name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.example.name
}

# ECS Service Name
output "ecs_service_name" {
  value = aws_ecs_service.example.name
}

# Application Load Balancer (ALB) FQDN
output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}