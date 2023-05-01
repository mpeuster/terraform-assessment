output "admin_passwords" {
  value       = random_password.admin_password.*.result
  sensitive   = true
  description = "Generated admin passwords for the VMs."
}

output "ping_results" {
  #value       = data.remote_file.ping_results.*.content
  # nicely format the output to include result and source/destination IPs
  value = { for i, v in data.remote_file.ping_results : i => {
    "result" = v.content,
    "src"    = tolist(aws_network_interface.private)[i].private_ip,
    "dst"    = tolist(aws_network_interface.private)[(i + 1) % length(aws_network_interface.private)].private_ip,
  } }
  description = "Ping results pass/fail for each VM. Map vm_index => {result, src, dst}"
}

output "ping_aggregated" {
  value       = (contains(tolist(data.remote_file.ping_results.*.content), "fail") ? "fail" : "pass")
  description = "Aggregated ping result"
}

output "ping_logs" {
  value       = data.remote_file.ping_logs.*.content
  description = "Full ping output for debugging. Not part of the requirements."
}