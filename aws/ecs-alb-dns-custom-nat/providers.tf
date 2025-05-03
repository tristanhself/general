# Declare Terraform Version and Providers
terraform {

  # Declare Terraform Version
  required_version = ">=1.8.2"

  # Declare Terraform Providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Declare the local state location.
  backend "local" {
    path = "state_data/terraform.tfstate"
  }

}

# Configure AWS Provider
provider "aws" {
  region = "eu-west-2"
}