terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "cluster_name" {
    type = string
    default = "DEV_EKS"
}

variable "node_group_name" {
    type = string
    default = "D_NG"
  
}