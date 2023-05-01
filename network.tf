# Basic VPC, routing and subnet setup.

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
resource "aws_route_table_association" "subnet-rtbl" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rtbl.id
}

resource "aws_security_group" "private_allow_ping" {
  name        = "private_allow_ping"
  description = "Allow ping within the private subnet"
  vpc_id      = aws_vpc.main.id
  tags        = var.common_tags

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
  tags        = var.common_tags

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