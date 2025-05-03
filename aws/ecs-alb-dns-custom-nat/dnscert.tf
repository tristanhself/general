// DNS Record and Certificate -----------------------------------------------------------------------------------------------------------------------------------------------

// DNS Record -----------------------------------------------------------------------------------------------------------------------------------------------

# We already have a Route53 Zone created, so we just want to add an A record to that zone for "www" and the "apex" A record.

resource "aws_route53_record" "www" {
  zone_id = var.route53zone
  name    = "www.${var.domainname}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.app_lb.dns_name]
}

resource "aws_route53_record" "root" {
  zone_id = var.route53zone
  name    = var.domainname
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

// Certificate and DNS Validation Record  -------------------------------------------------------------------------------------------------------------------

# Create ACM certificate
resource "aws_acm_certificate" "example" {
  domain_name       = var.domainname
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domainname}"]

  # Specify validation options for DNS
  lifecycle {
    create_before_destroy = true
  }
}

# Create Route 53 Record for DNS validation
resource "aws_route53_record" "cert_validation" {
  zone_id         = var.route53zone
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.example.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.example.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.example.domain_validation_options)[0].resource_record_type
  ttl             = 60
}

# Perform the certificate validation
resource "aws_acm_certificate_validation" "cert_validate_action" {
  certificate_arn = aws_acm_certificate.example.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}