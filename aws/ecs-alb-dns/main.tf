// VPC, Subnets, IGW, Route Table(s) and Security Group -------------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
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
    Name = "VPC_Public-RouteTable"
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

