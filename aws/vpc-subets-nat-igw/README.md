# Simple VPC Deployment Pattern

A simple VPC deployment pattern which includes a simple configuration that has been tested and can be used to build a new infrastructure from. It uses Terraform and uses local state storage (within a directory called "state_data"), for production uses it is mandated to use some form of remote state storage.

## Pattern

The pattern within the template includes the following infrastructure components, it is set to use the eu-west-2 (London) region, it is highly available and components are spread over two availability zones.

The EC2 instances within the private subnets (A, B, C and D) are able to communicate with each other across their subnets, however they can only reach the Internet via the NATGW (in Public Subnet A and B), there is no inbound access (from the Internet) permitted.

* VPC
* IGW (Internet Gateway)
* 2 x NATGW (NAT Gateways) in Availablity Zone A and B
* 2 x EIP (Elastic IP Addresses v4) attached to NATGWs
* 6 x Subnets
  * 2 x Public Subnets (A & B)
  * 2 x Private Subnets (A & B) with EC2 Instance A and EC2 Instance B
  * 2 x Private Subnets (C & D) with EC2 Instance C and EC2 Instance D
* 6 x Route Tables (one per Subnet)
* IAM Role(s) and SSM Configuration

## Usage

A simple guide is given below to use this pattern, however you should consult your local workstation configuration before use.

1. Clone the repository to your workstation.

2. CD to the cloned repository.
```
cd ~/vscode/aws/snippets/terraform/vpc-subnets-nat-igw
```

3. Logon with SSO to AWS.
```
export AWS_PROFILE=MyPROFILE
aws sso login --profile=$AWS_PROFILE
```

4. Initalise the environment.
```
terraform init
```

5. Deploy the template.
```
terraform apply
```
