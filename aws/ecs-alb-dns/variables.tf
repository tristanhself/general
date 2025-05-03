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

