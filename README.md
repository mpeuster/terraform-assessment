# terraform-assessment

by Manuel Peuster (manuel@peuster.de)

## Summary

The provided solution assumes AWS as cloud provider.

TODO explain solution


## Used Providers

- AWS
- remote (https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file)

## Usage

### Configuration

Ensure you have valid AWS credentials configured, e.g.,

```sh
export AWS_ACCESS_KEY_ID="foo-bar"
export AWS_SECRET_ACCESS_KEY="foo-bar"
```

Update the `demo.auto.tfvars` file to configure the deployment.

TODO: Explain vars


### Example

#### Starting the demo:

```sh
terraform init
terraform plan
terraform apply
```

##### Accessing the VMs

For debugging purposes you might want to access the VMs. To do so you can use AWS Serial Console and the random passwords that have been generated during infrastructure setup.

Get the passwords:

```sh
terraform output -json
```

Go to AWS Web Console and open the instance's AWS serial console.
To log in, enter user: `root` and the password dereived from the output.

> Note: A better practice is to spin up a bastion host that allows to connect via SSH and can be used as a jumpbox to the private VM instances. This part was skipped here as it was no explicit requirement for the assessment. But would be the way to go for a productions system.

Destroying the demo:

```sh
terraform destroy
```

