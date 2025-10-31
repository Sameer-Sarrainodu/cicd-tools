terraform {
  required_providers {
   aws={
    source = "hashicorp/aws"
    version = "6.15.0"

   }
  }
  backend "s3" {
    bucket = "84s-remote-sam-dev"
    key = "roboshop-dev-cicd"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
    region = "us-east-1"
}
