terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.1"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.provider_aws.region
}

resource "random_password" "admin_password" {
  length  = 12
  special = false
  count   = var.vm_pool_params.vm_count
}

resource "aws_key_pair" "vm_pool_key" {
  key_name   = "aws dmeo key"
  public_key = file(var.ssh_keys.public_key_path)
  tags       = var.common_tags
}

# in order to make the round robin ping easy, we assign predictable IPs to each of the VM instances
resource "aws_network_interface" "private" {
  count           = var.vm_pool_params.vm_count
  subnet_id       = aws_subnet.private.id
  private_ips     = [cidrhost(var.subnet_params.cidr_block, count.index + 10)]
  security_groups = [aws_security_group.private_allow_ping.id, aws_security_group.public_allow_ssh.id]
  tags            = var.common_tags
}

# elastic IP for public SSH access to the intance (remote-exec)
resource "aws_eip" "public-eip" {
  count    = var.vm_pool_params.vm_count
  instance = aws_instance.vm_pool[count.index].id
  vpc      = true
  tags     = var.common_tags
}

# actual resource that defines the N VMs to be created
resource "aws_instance" "vm_pool" {
  count         = var.vm_pool_params.vm_count
  ami           = lookup(var.vm_pool_params_individual_overwrite, count.index, var.vm_pool_params).vm_image
  instance_type = lookup(var.vm_pool_params_individual_overwrite, count.index, var.vm_pool_params).vm_flavor
  key_name      = aws_key_pair.vm_pool_key.key_name
  tags          = var.common_tags

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