# Provider / cloud configurations
provider_aws = {
  region = "eu-north-1" # north-1 because it seems to be the cheapest eu regions at the moment
}

# Local paths to your SSH keys that shall be used to access the VMs for remote execution. Please change.
ssh_keys = {
  public_key_path  = "~/.ssh/aws_demo.pub"
  private_key_path = "~/.ssh/aws_demo"
}

# Remote user of the VMs
remote_user = "ec2-user" # default user for AWS Linux AMIs

# Generic tags applied to all resources
common_tags = {
  "project" = "Bosch.io Assessment"
}

# VPC configuration
vpc_params = {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Subnet configuration
subnet_params = {
  cidr_block = "10.0.100.0/24" # /24 is more than enough for the requirement "between 2 and 100 VMs"
}

# VM pool default configuration
vm_pool_params = {
  vm_count  = 3                       # Number of VMs to be created (N)
  vm_flavor = "t3.micro"              # VM flavor to be used if no individual overwrite for this instance is defined
  vm_image  = "ami-0577c11149d377ab7" # VM image to be used if no individual overwrite for this instance is defined
}

# Individual VM configuration:
# Allow to overwrite the default flavor and image for each individual VM. This might look a bit odd at first, but
# the requirement stated that these parameters need to be configurable for each VM individually.
# To avoid the need to create a map/list with 100 entries, if 100 common VMs shall be created, I picked this overwriting
# approach.
# 
# map[count.index] -> object
vm_pool_params_individual_overwrite = {
  1 = { # example: Use t3.small for VM with index 1 (instead of t3.micro)
    vm_flavor = "t3.small"
    vm_image  = "ami-0577c11149d377ab7"
  }
}