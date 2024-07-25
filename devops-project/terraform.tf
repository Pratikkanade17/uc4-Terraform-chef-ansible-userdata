# Terraform Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }    
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }            
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {}      
}

# Provider Block
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

