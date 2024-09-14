# AWS Transit Gateway

The ATransit Gateway 1 has state managed via Terraform. The Terraform State is stored within an S3 Bucket, the Terraform Lock File is stored within the AWS DynamoDB.

AWS Account: **net-production**

Terraform State AWS S3 Bucket: **net-production-tgw**

Terraform State Lock AWS DynamoDB Table: **net-production-tgw**

## Using this Terraform Configuration

### Pre-requisites

* Access to the AWS console for the relevant account.
* Terraform and git installed and in your path

### Prepare the Infrastructure

* Clone this repo.

* Run Terraform (You'll need to do Terraform init if you've not run it before)

```
terraform init
terraform plan
```

## Terraform Bootstapping Procedure (Reference Only)

The following is provided for reference only and is required to first bootstrap the Terraform environment by creating the required AWS S3 Bucket and AWS DynamoDB Table to store and lock the Terraform State; once bootstrapped all further configuration changes are made via Terraform.

1. Run the following AWS Cloudformation Template to bootstrap the AWS resources needed to manage the AWS resources with Terraform safely.

```
aws cloudformation create-stack --template-body file://bootstrap.yaml --stack-name net-production-tgw  --capabilities CAPABILITY_NAMED_IAM
```

2. Run the following Terraform commands to initalise your Terraform environment, (any) existing Terraform state will be retrieved from the AWS S3 Terraform State Bucket.
```
terraform init
```

Your Terraform environment is now ready for use.

## Additional Information

[Example](https://dev.to/charlesuneze/configuring-a-transit-gateway-between-3-vpcs-using-terraform-4off)
[Cross Account Example](https://github.com/hashicorp/terraform-provider-aws/blob/main/examples/transit-gateway-cross-account-vpc-attachment/main.tf)
[AWS Egress to Internet](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/centralized-egress-to-internet.html)