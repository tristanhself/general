
// https://dev.to/charlesuneze/configuring-a-transit-gateway-between-3-vpcs-using-terraform-4off
// https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/centralized-egress-to-internet.html
// https://towardsdatascience.com/connecting-to-an-ec2-instance-in-a-private-subnet-on-aws-38a3b86f58fb
// https://devopslearning.medium.com/21-days-of-aws-using-terraform-day-14-introduction-to-transit-gateway-using-terraform-8bbc3ce00b4c

// VPCs ----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "VPC_A" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_A"
  }
}

resource "aws_vpc" "VPC_B" {
  cidr_block       = "10.2.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_B"
  }
}

// Subnets ----------------------------------------------------------------------------------------------------------------------------------------


resource "aws_subnet" "VPC_A-Private-Subnet" {
  vpc_id                  = aws_vpc.VPC_A.id
  cidr_block              = "10.1.0.0/24"
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "VPC_A-Private-Subnet"
  }
}

resource "aws_subnet" "VPC_B-Private-Subnet" {
  vpc_id                  = aws_vpc.VPC_B.id
  cidr_block              = "10.2.0.0/24"
  availability_zone       = "eu-west-2b"

  tags = {
    Name = "VPC_B-Private-Subnet"
  }
}

// Route Tables

resource "aws_route_table" "VPC_A-Private-RouteTable" {
  vpc_id   = aws_vpc.VPC_A.id

  tags = {
    Name         = "VPC_A-Private-RouteTable"
  }
}
resource "aws_route_table_association" "VPC_A-Private-RouteTable-Assoc" {
  subnet_id      = aws_subnet.VPC_A-Private-Subnet.id
  route_table_id = aws_route_table.VPC_A-Private-RouteTable.id
}
resource "aws_route" "VPC_A-Private-RouteTable-Route1" {
  route_table_id         = aws_route_table.VPC_A-Private-RouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
}

resource "aws_route_table" "VPC_B-Private-RouteTable" {
  vpc_id   = aws_vpc.VPC_B.id

  tags = {
    Name         = "VPC_B-Private-RouteTable"
  }
}
resource "aws_route_table_association" "VPC_B-Private-RouteTable-Assoc" {
  subnet_id      = aws_subnet.VPC_B-Private-Subnet.id
  route_table_id = aws_route_table.VPC_B-Private-RouteTable.id
}
resource "aws_route" "VPC_B-Private-RouteTable-Route1" {
  route_table_id         = aws_route_table.VPC_B-Private-RouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
}

// Transit Gateway

resource "aws_ec2_transit_gateway" "TGW" {
  description                     = "Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  vpn_ecmp_support = "enable"

  tags = {
    Name = "TGW"
  }
}

// Transit Gateway VPC Attachments

resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_A-TGW-Attachment" {
  subnet_ids         = [aws_subnet.VPC_A-Private-Subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  vpc_id             = aws_vpc.VPC_A.id

  tags = {
    Name = "VPC_A-TGW-Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_B-TGW-Attachment" {
  subnet_ids         = [aws_subnet.VPC_B-Private-Subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  vpc_id             = aws_vpc.VPC_B.id

  tags = {
    Name = "VPC_B-TGW-Attachment"
  }
}

// Security Groups

resource "aws_security_group" "VPC_A-SecurityGroup-1" {
  vpc_id = aws_vpc.VPC_A.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
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
    Name = "VPC_A-SecurityGroup-1"
  }
}

resource "aws_security_group" "VPC_B-SecurityGroup-1" {
  vpc_id = aws_vpc.VPC_B.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
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
    Name = "VPC_B-SecurityGroup-1"
  }
}

// EC2 Instances ----------------------------------------------------------------------------------------------------------------------------

// VPC A - EC2 Instance
resource "aws_instance" "VPC_A-Instance-1" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2a"
  key_name          = ""
  subnet_id         = aws_subnet.VPC_A-Private-Subnet.id
  security_groups   = ["${aws_security_group.VPC_A-SecurityGroup-1.id}"]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "VPC_A-Instance-1"
  }
}

// VPC B - EC2 Instance
resource "aws_instance" "VPC_B-Instance-1" {
  ami               = "ami-008ea0202116dbc56"
  instance_type     = "t2.micro"
  tenancy           = "default"
  availability_zone = "eu-west-2b"
  key_name          = ""
  subnet_id         = aws_subnet.VPC_B-Private-Subnet.id
  security_groups   = ["${aws_security_group.VPC_B-SecurityGroup-1.id}"]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "VPC_B-Instance-1"
  }
}

// EC2 IAM Role -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
    name = "ec2-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = ""
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
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2-ssm-profile"
    role = aws_iam_role.ec2_role.name
}

// Flow Logs IAM Role -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "role_lab_flow_logs" {
  name = "role_lab_flow_logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// IAM Role policy for flow logs -----------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "IAM_Role_Policy_for_Flow_Log" {
  name = "IAM_Role_Policy_for_Flow_Log"
  role = aws_iam_role.role_lab_flow_logs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

// Cloudwatch TGW Log Group ------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "VPC_Log_Group" {
  name              = "VPC_Log_Group"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "VPN_Tunnel1_Log_Group" {
  name              = "PN_Tunnel1_Log_Group"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "VPN_Tunnel2_Log_Group" {
  name              = "PN_Tunnel2_Log_Group"
  retention_in_days = 7
}

// VPC A Flow Logs  ----------------------------------------------------------------------------------------------------------------------

resource "aws_flow_log" "VPC_A_FlowLogs" {
  iam_role_arn    = aws_iam_role.role_lab_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.VPC_Log_Group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.VPC_A.id

  tags = {
    Name = "VPC_A_FlowLogs"
  }
}

resource "aws_flow_log" "VPC_B_FlowLogs" {
  iam_role_arn    = aws_iam_role.role_lab_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.VPC_Log_Group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.VPC_B.id

  tags = {
    Name = "VPC_B_FlowLogs"
  }
}

// Output --------------------------------------------------------------------------------------------------------------------------------

output "VPC_A-Instance-1_Private-IP" {
  value = aws_instance.VPC_A-Instance-1.private_ip
}

output "VPC_B-Instance-1_Private-IP" {
  value = aws_instance.VPC_B-Instance-1.private_ip
}