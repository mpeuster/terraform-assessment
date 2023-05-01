variable "provider_aws" {
  type = map(string)
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_params" {
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
}

variable "subnet_params" {
  type = object({
    cidr_block = string
  })
}

variable "vm_pool_params" {
  type = object({
    vm_count  = number
    vm_flavor = string
    vm_image  = string
  })
}


