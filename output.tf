output "admin_passwords" {
  value       = random_password.admin_password.*.result
  sensitive   = true
  description = "Generated admin passwords for the VMs"
}

output "ping_results" {
  value       = data.remote_file.ping_results.*.content
  description = "Ping results pass/fail."
}

output "ping_logs" {
  value       = data.remote_file.ping_logs.*.content
  description = "Full ping output for debugging. Not part of the requirements."
}