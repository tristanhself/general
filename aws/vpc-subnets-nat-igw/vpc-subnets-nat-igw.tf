// VPCs ----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "vpcsubnetsnatigw-VPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "vpcsubnetsnatigw-VPC"
  }
}

// Internet Gateway ----------------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "vpcsubnetsnatigw-IGW" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-IGW"
  }
}

// Elastic IP for NAT Gateway 1 --------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "vpcsubnetsnatigw-EIP1" {
  domain     = "vpc"
  depends_on = [aws_vpc.vpcsubnetsnatigw-VPC]
}

// NAT Gateway 1 -----------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_nat_gateway" "vpcsubnetsnatigw-NGW1" {
  subnet_id     = aws_subnet.vpcsubnetsnatigw-PublicA.id
  allocation_id = aws_eip.vpcsubnetsnatigw-EIP1.id

  tags = {
    Name = "vpcsubnetsnatigw-NGW1"
  }
}

// Elastic IP for NAT Gateway 2 --------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "vpcsubnetsnatigw-EIP2" {
  domain     = "vpc"
  depends_on = [aws_vpc.vpcsubnetsnatigw-VPC]
}

// NAT Gateway 2 -----------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_nat_gateway" "vpcsubnetsnatigw-NGW2" {
  subnet_id     = aws_subnet.vpcsubnetsnatigw-PublicB.id
  allocation_id = aws_eip.vpcsubnetsnatigw-EIP2.id

  tags = {
    Name = "vpcsubnetsnatigw-NGW2"
  }
}

// Public Subnets ------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "vpcsubnetsnatigw-PublicA" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "vpcsubnetsnatigw-PublicA"
  }
}

resource "aws_subnet" "vpcsubnetsnatigw-PublicB" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "vpcsubnetsnatigw-PublicB"
  }
}

// Private Subnets ----------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "vpcsubnetsnatigw-PrivateA" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "vpcsubnetsnatigw-PrivateA"
  }
}

resource "aws_subnet" "vpcsubnetsnatigw-PrivateB" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "vpcsubnetsnatigw-PrivateB"
  }
}

resource "aws_subnet" "vpcsubnetsnatigw-PrivateC" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "vpcsubnetsnatigw-PrivateC"
  }
}

resource "aws_subnet" "vpcsubnetsnatigw-PrivateD" {
  vpc_id                  = aws_vpc.vpcsubnetsnatigw-VPC.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "vpcsubnetsnatigw-PrivateD"
  }
}

// Route Table - Public Subnet A --------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PublicA-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PublicA-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PublicA-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PublicA.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PublicA-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PublicA-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PublicA-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpcsubnetsnatigw-IGW.id
}

// Route Table - Public Subnet B --------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PublicB-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PublicB-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PublicB-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PublicB.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PublicB-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PublicB-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PublicB-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpcsubnetsnatigw-IGW.id
}

// Route Table - Private Subnet A -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PrivateA-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PrivateA-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PrivateA-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PrivateA.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PrivateA-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PrivateA-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PrivateA-RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpcsubnetsnatigw-NGW1.id
}

// Route Table - Private Subnet B ----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PrivateB-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PrivateB-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PrivateB-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PrivateB.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PrivateB-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PrivateB-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PrivateB-RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpcsubnetsnatigw-NGW2.id
}

// Route Table - Private Subnet C -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PrivateC-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PrivateC-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PrivateC-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PrivateC.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PrivateC-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PrivateC-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PrivateC-RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpcsubnetsnatigw-NGW1.id
}

// Route Table - Private Subnet D ----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "vpcsubnetsnatigw-PrivateD-RT" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  tags = {
    Name = "vpcsubnetsnatigw-PrivateD-RT"
  }
}

resource "aws_route_table_association" "vpcsubnetsnatigw-PrivateD-RT-Assoc" {
  subnet_id      = aws_subnet.vpcsubnetsnatigw-PrivateD.id
  route_table_id = aws_route_table.vpcsubnetsnatigw-PrivateD-RT.id
}

resource "aws_route" "vpcsubnetsnatigw-PrivateD-RT-Route1" {
  route_table_id         = aws_route_table.vpcsubnetsnatigw-PrivateD-RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpcsubnetsnatigw-NGW2.id
}

// EC2 IAM Role -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "vpcsubnetsnatigw-ec2_role" {
  name = "vpcsubnetsnatigw-ec2_role"

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
resource "aws_iam_role_policy_attachment" "vpcsubnetsnatigw-ec2_role_attach" {
  role       = aws_iam_role.vpcsubnetsnatigw-ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "vpcsubnetsnatigw-ec2_profile" {
  name = "vpcsubnetsnatigw-ec2_profile"
  role = aws_iam_role.vpcsubnetsnatigw-ec2_role.name
}

// EC2 User Data -----------------------------------------------------------------------------------------------------------------------------------------

# User data: install nginx, make self-signed cert, HTTPS server block + redirect
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf -y install httpd
    cat >/var/www/html/index.html <<'HTML'
    <!doctype html>
    <html><head><meta charset="utf-8"><title>Hello from EC2</title></head>
    <body style="font-family: system-ui; margin: 3rem">
      <h1>It works 🎉</h1>
    </body></html>
    HTML
    systemctl enable --now httpd
  EOF
}

// EC2 User Data -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "vpcsubnetsnatigw-SG1" {
  vpc_id = aws_vpc.vpcsubnetsnatigw-VPC.id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpcsubnetsnatigw-SG1"
  }
}

// EC2 Instance 1 -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "vpcsubnetsnatigw-InstanceA" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2a"
  key_name          = ""
  subnet_id         = aws_subnet.vpcsubnetsnatigw-PrivateA.id
  vpc_security_group_ids = [aws_security_group.vpcsubnetsnatigw-SG1.id]
  iam_instance_profile   = aws_iam_instance_profile.vpcsubnetsnatigw-ec2_profile.name
  user_data              = local.user_data

  tags = {
    Name = "vpcsubnetsnatigw-InstanceA"
  }
}

// EC2 Instance 2 -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "vpcsubnetsnatigw-InstanceB" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2b"
  key_name          = ""
  subnet_id         = aws_subnet.vpcsubnetsnatigw-PrivateB.id
  vpc_security_group_ids = [aws_security_group.vpcsubnetsnatigw-SG1.id]
  iam_instance_profile   = aws_iam_instance_profile.vpcsubnetsnatigw-ec2_profile.name
  user_data              = local.user_data

  tags = {
    Name = "vpcsubnetsnatigw-InstanceB"
  }
}

// EC2 Instance 3 -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "vpcsubnetsnatigw-InstanceC" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2a"
  key_name          = ""
  subnet_id         = aws_subnet.vpcsubnetsnatigw-PrivateC.id
  vpc_security_group_ids = [aws_security_group.vpcsubnetsnatigw-SG1.id]
  iam_instance_profile   = aws_iam_instance_profile.vpcsubnetsnatigw-ec2_profile.name
  user_data              = local.user_data

  tags = {
    Name = "vpcsubnetsnatigw-InstanceC"
  }
}

// EC2 Instance 4 -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "vpcsubnetsnatigw-InstanceD" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2b"
  key_name          = ""
  subnet_id         = aws_subnet.vpcsubnetsnatigw-PrivateD.id
  vpc_security_group_ids = [aws_security_group.vpcsubnetsnatigw-SG1.id]
  iam_instance_profile   = aws_iam_instance_profile.vpcsubnetsnatigw-ec2_profile.name
  user_data              = local.user_data

  tags = {
    Name = "vpcsubnetsnatigw-InstanceD"
  }
}
