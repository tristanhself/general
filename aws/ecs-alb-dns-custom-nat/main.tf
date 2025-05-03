// VPC, Subnets, IGW, Route Table(s) and Security Group -------------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "priv_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "priv_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_security_group"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.main.id

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
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "VPC_IGW"
  }
}

resource "aws_route_table" "VPC_Public-RouteTable" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-RouteTable"
  }
}

resource "aws_route" "VPC_Public-RouteTable-Route1" {
  route_table_id         = aws_route_table.VPC_Public-RouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "VPC_Public-RouteTable-Assoc-Public-Subnet-A" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.VPC_Public-RouteTable.id
}

resource "aws_route_table_association" "VPC_Public-RouteTable-Assoc-Public-Subnet-B" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.VPC_Public-RouteTable.id
}

// Elastic IP for NAT Gateway
resource "aws_eip" "natgateway_eip1" {
  domain     = "vpc"
  depends_on = [aws_vpc.main]
}

resource "aws_eip" "natgateway_eip2" {
  domain     = "vpc"
  depends_on = [aws_vpc.main]
}

// NAT Gateway 1
resource "aws_nat_gateway" "natgateway_nat_gw_1" {
  subnet_id     = aws_subnet.subnet_a.id
  allocation_id = aws_eip.natgateway_eip1.id

  tags = {
    Name = "main-NATGW-1"
  }
}

// NAT Gateway 2
resource "aws_nat_gateway" "natgateway_nat_gw_2" {
  subnet_id     = aws_subnet.subnet_b.id
  allocation_id = aws_eip.natgateway_eip2.id

  tags = {
    Name = "main-NATGW-1"
  }
}

# Private Route Table A ---------------------------------------------------------------------------------------
resource "aws_route_table" "main-RouteTable-Private-A" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-RouteTable-Private-A"
  }
}

resource "aws_route" "main-RouteTable-Private-A-Route1" {
  route_table_id         = aws_route_table.main-RouteTable-Private-A.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgateway_nat_gw_1.id
}

resource "aws_route_table_association" "main-RouteTable-Private-A-assoc" {
  subnet_id      = aws_subnet.priv_subnet_a.id
  route_table_id = aws_route_table.main-RouteTable-Private-A.id
}

# Private Route Table B ---------------------------------------------------------------------------------------
resource "aws_route_table" "main-RouteTable-Private-B" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-RouteTable-Private-B"
  }
}

resource "aws_route" "main-RouteTable-Private-B-Route1" {
  route_table_id         = aws_route_table.main-RouteTable-Private-B.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgateway_nat_gw_2.id
}

resource "aws_route_table_association" "main-RouteTable-Private-B-assoc" {
  subnet_id      = aws_subnet.priv_subnet_b.id
  route_table_id = aws_route_table.main-RouteTable-Private-B.id
}