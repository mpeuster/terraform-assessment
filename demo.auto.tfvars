provider_aws = {
  region = "eu-north-1" # north-1 because it seems to be the cheapest eu regions at the moment
}

common_tags = {
  "project" = "Bosch.io Assessment"
}

vpc_params = {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

subnet_params = {
  cidr_block = "10.0.100.0/24" # /24 is more than enough for the requirement "between 2 and 100 VMs"
}

vm_pool_params = {
  vm_count  = 2
  vm_flavor = "t3.micro"
  vm_image  = "ami-0577c11149d377ab7" # Amazon Linux 2 2023 AMI
}