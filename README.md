# terraform-assessment

by Manuel Peuster (manuel@peuster.de)

## Summary

This project creates a VPC with N VMs and executes a ping-test in "round-robin" fashion between them.
The provided solution assumes AWS as cloud provider.

The core idea behind the setup is to assign each VM a specific private IP (index + 10) within the private subnet,
to simplify the execution of the ping test later on:

```
ping_dst = (index + 1) mod N
```

The solution then uses the remote-exec provisioner as part of a null_resource to execute the pings once all instances are ready.
The results of the pings are written to files on the VMs and are then collected by the `remote` provider and made available as local data sources.

Finally the collected information is aggregated / formatted and written to the output.

> Note: The SSH connections for the remote-exec and file collection are directly done to the VMs (each VM gets a EIP). This is good enough for this demo. For a production system I would favor a solution with a single bastion host that acts as a jumpbox to the private network.


### Example

Output of an example execution with N=3:


```sh
terraform apply
```

```
ping_results = {
  "0" = {
    "dst" = "10.0.100.11"
    "result" = "pass"
    "src" = "10.0.100.10"
  }
  "1" = {
    "dst" = "10.0.100.12"
    "result" = "pass"
    "src" = "10.0.100.11"
  }
  "2" = {
    "dst" = "10.0.100.10"
    "result" = "pass"
    "src" = "10.0.100.12"
  }
}
```


## Used Providers

- AWS
- [remote](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file): used to fetch the ping results

## Usage

### Files

This project contains the following files:

```
.
├── demo.auto.tfvars            tfvars used for the demo
├── LICENSE
├── main.tf                     main infra setup (VMs)
├── network.tf                  network and VPC setup
├── output.tf                   outputs and formatting
├── ping.tf                     the ping test
├── README.md
├── userdata                    helpers
│   └── pwsetup.sh
└── variables.tf                variable definitions
```

### Configuration

Ensure you have valid AWS credentials configured, e.g.,

```sh
export AWS_ACCESS_KEY_ID="foo-bar"
export AWS_SECRET_ACCESS_KEY="foo-bar"
```

All configurations can be found in `demo.auto.tfvars`.

> Note: Make sure to update the paths given in the ssh_keys variable to be able to run the demo with remote-exec functionality.


#### demo.auto.tfvars:

```terraform
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
```

### Example

#### Starting the demo:

```sh
terraform init
terraform plan
terraform apply
```

#### Inspecting the putputs

```sh
# simple
terraform output

# get list of ping results pass/fail
terraform output -json | jq -r .ping_results.value

# get list of full ping result logs (measurements)
terraform output -json | jq -r .ping_logs.value
```

#### Accessing the VMs

For debugging purposes you might want to access the VMs via AWS Serial Console and the random passwords that have been generated during infrastructure setup.

Get the passwords:

```sh
terraform output -json
```

Go to AWS Web Console and open the instance's AWS serial console.
To log in, enter user: `root` and the password derived from the output.

#### Destroying the demo

```sh
terraform destroy
```

