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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = var.common_tags
}

resource "aws_route_table" "rtbl" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.common_tags
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rtbl.id
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
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.subnet_params.cidr_block]
  }
}

resource "aws_security_group" "public_allow_ssh" {
  name        = "public_allow_ssh"
  description = "Allow SSH to the instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # generirc egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "private" {
  count           = var.vm_pool_params.vm_count
  subnet_id       = aws_subnet.private.id
  private_ips     = [cidrhost(var.subnet_params.cidr_block, count.index + 10)] # note: in order to make the round robin ping easy, we assign predictable IPs to each of the VM instances
  security_groups = [aws_security_group.private_allow_ping.id, aws_security_group.public_allow_ssh.id]
}

# elastic IP for public SSH access to the intance
resource "aws_eip" "public-eip" {
  count    = var.vm_pool_params.vm_count
  instance = aws_instance.vm_pool[count.index].id
  vpc      = true
}

resource "aws_key_pair" "vm_pool_key" {
  key_name   = "aws dmeo key"
  public_key = file(var.ssh_keys.public_key_path)
}

resource "aws_instance" "vm_pool" {
  count         = var.vm_pool_params.vm_count
  ami           = var.vm_pool_params.vm_image
  instance_type = var.vm_pool_params.vm_flavor
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

resource "null_resource" "pinger" {
  count = var.vm_pool_params.vm_count

  triggers = {
    all_pool_instances = join(",", aws_instance.vm_pool.*.id)
  }

  # configure external SSH access to the instances to be able to use remote-exec
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.ssh_keys.private_key_path)
    host        = aws_eip.public-eip[count.index].public_ip
  }

  provisioner "remote-exec" {

    inline = ["ping -c1 10.0.100.11 > /tmp/ping.log"]
  }


}