terraform {

  backend "s3" {
    bucket                  = "net-production-tgw"
    dynamodb_table          = "net-production-tgw"
    key                     = "net-production-tgw-state"
    region                  = "eu-west-2"
  }

}

provider "aws" {
  region                    = "eu-west-2"
}