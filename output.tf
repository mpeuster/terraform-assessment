output "admin_passwords" {
  value       = random_password.admin_password.*.result
  sensitive   = true
  description = "Generated admin passwords for the VMs"
}