terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.69"
    }
  }
  required_version = "~> 1.9"
}

provider "aws" {
    region = var.region_tf
}

resource "aws_key_pair" "key" {
    key_name = "key"
    public_key = file("")
}

resource "aws_security_group" "wordpress_sg" {
    name = "wordpress_sg"
    description = "Permitir trafico HTTP y HTTPS, asi como SSH"
}