// VPC ----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "VPC_test-sP" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_test-sP"
  }
}

// Subnets -------------------------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "VPC_test-sP-Public-Subnet-A" {
  vpc_id                  = aws_vpc.VPC_test-sP.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "VPC_test-sP-Public-Subnet-A"
  }
}

// Route Tables ----------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "VPC_test-sP-Public-RouteTable" {
  vpc_id = aws_vpc.VPC_test-sP.id

  tags = {
    Name = "VPC_test-sP-Public-RouteTable"
  }
}

resource "aws_route" "VPC_test-sP-Public-RouteTable-Route1" {
  route_table_id         = aws_route_table.VPC_test-sP-Public-RouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC_test-sP-IGW.id
}

resource "aws_route_table_association" "VPC_test-sP-Public-RouteTable-Assoc-Public-Subnet-A" {
  subnet_id      = aws_subnet.VPC_test-sP-Public-Subnet-A.id
  route_table_id = aws_route_table.VPC_test-sP-Public-RouteTable.id
}

// Internet Gateway ----------------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "VPC_test-sP-IGW" {
  vpc_id = aws_vpc.VPC_test-sP.id

  tags = {
    Name = "VPC_test-sP-IGW"
  }
}

// Create Elastic IP Address -------------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "VPC_test-sP-EIP1" {
  domain   = "vpc"
  instance = aws_instance.VPC_test-sP-Instance-1.id

  tags = {
    Name = "VPC_test-sP-EIP1"
  }
}

// DNS Record -------------------------------------------------------------------------------------------------------------------------

# We already have a Route53 Zone created, so we just want to add an A record to that zone.

variable "route53zone" {
  description = "String holding Route53 Hosted zone ID"
  type        = string
  default     = "ZoneIDINHERE"
}

resource "aws_route53_record" "www" {
  zone_id = var.route53zone
  name    = "www.domain.com"
  type    = "A"
  ttl     = 60
  records = [aws_eip.VPC_test-sP-EIP1.public_ip]
}

resource "aws_route53_record" "root" {
  zone_id = var.route53zone
  name    = "domain.com"
  type    = "A"

  alias {
    #name                   = "www.domain.com"
    name                   = aws_route53_record.www.fqdn
    zone_id                = var.route53zone
    
    evaluate_target_health = false
  }
}

// EC2 IAM Role -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Need to add in another policy attachment for the access to the SSM parameters...

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_role.name
}

// Security Groups ----------------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "VPC_test-sP-SecurityGroup-1" {
  vpc_id = aws_vpc.VPC_test-sP.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "VPC_test-sP-SecurityGroup-1"
  }
}

// EC2 Instances ----------------------------------------------------------------------------------------------------------------------------

// EC2 Instance 1
resource "aws_instance" "VPC_test-sP-Instance-1" {
  #ami               = "ami-008ea0202116dbc56"
  ami               = "ami-05c172c7f0d3aed00"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2a"
  key_name          = ""
  subnet_id         = aws_subnet.VPC_test-sP-Public-Subnet-A.id
  #security_groups      = ["${aws_security_group.VPC_dns-ns-SecurityGroup-1.id}"]
  vpc_security_group_ids = [aws_security_group.VPC_test-sP-SecurityGroup-1.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/user_data.sh")

  tags = {
    Name      = "VPC_test-sP-Instance-1",
    Terraform = "true"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }
}
