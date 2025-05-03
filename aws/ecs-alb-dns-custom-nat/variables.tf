// DNS Variables ----------------------------------------------------------------------------

variable "route53zone" {
  description = "String holding Route53 Hosted zone ID"
  type        = string
  default     = "<Zone ID>"
}

variable "domainname" {
  description = "String holding domain name"
  type        = string
  default     = "domain.com"
}

variable "ecrimageuri" {
  # The image URL can be obtained from the Amazon Elastic Container Registry for the particular image required.
  description = "ECS Image URI"
  type        = string
  default     = "123455379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world:1.0"
}
