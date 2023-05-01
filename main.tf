terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

resource "random_password" "admin_password" {
  length  = 12
  special = false
  count   = var.vm_pool_params.vm_count
}

provider "aws" {
  region = var.provider_aws.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_params.cidr_block
  enable_dns_hostnames = var.vpc_params.enable_dns_hostnames
  enable_dns_support   = var.vpc_params.enable_dns_support
  tags                 = var.common_tags
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_params.cidr_block
  tags       = var.common_tags
}

resource "aws_security_group" "private_allow_ping" {
  name        = "private_allow_ping"
  description = "Allow ping within the private subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow ping within the private subnet"
    from_port   = -1 # AWS uses this field to encode ICMP echo request type
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.subnet_params.cidr_block]
  }

  egress {
    description = "Allow ping within the private subnet"
    from_port   = -1 # AWS uses this field to encode ICMP echo request type
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.subnet_params.cidr_block]
  }
}

# note: in order to make the round robin ping easy, we assign specific IPs to each of the VM instances
resource "aws_network_interface" "private" {
  count       = var.vm_pool_params.vm_count
  subnet_id   = aws_subnet.private.id
  private_ips = [cidrhost(var.subnet_params.cidr_block, count.index + 10)]
  #private_ips = ["10.0.100.${count.index + 10}"]
  security_groups = [aws_security_group.private_allow_ping.id]
}

resource "aws_instance" "vm_pool" {
  count         = var.vm_pool_params.vm_count
  ami           = var.vm_pool_params.vm_image
  instance_type = var.vm_pool_params.vm_flavor
  #vpc_security_group_ids = [aws_security_group.private_allow_ping.id]
  tags = var.common_tags

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.private[count.index].id
  }

  # add a random password to the root user as per requirement
  # note: not sure about the requirement here, we could have generated a PW in the VM only, but I assume we are interested in getting the password as part of the outputs to use it
  user_data = base64encode(templatefile("${path.root}/userdata/pwsetup.sh", {
    admin_password = random_password.admin_password[count.index].result
    }
  ))
}