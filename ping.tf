# Everything related to the ping test

# null_resource to to run remote-exec on each instance
resource "null_resource" "pinger" {
  count = var.vm_pool_params.vm_count

  triggers = {
    all_pool_instances = join(",", aws_instance.vm_pool.*.id), # ensure we run after all instances are created
    exec_key           = uuid()                                # force the remote-exec to run on each apply
  }

  connection {
    type        = "ssh"
    user        = var.remote_user
    private_key = file(var.ssh_keys.private_key_path)
    host        = aws_eip.public-eip[count.index].public_ip
  }

  provisioner "remote-exec" {
    # Execute the ping test:
    # - dst: next IP is (count.index + 1) % var.vm_pool_params.vm_count: 0 -> 1 -> ... n-1 -> 0
    # - runs exactly one ping and writes pass / fail to a file, based on the exit code
    # - also logs the entire output of the ping command to ease debugging and better see what happens 
    inline = [
      "ping -c1 ${cidrhost(var.subnet_params.cidr_block, 10 + (count.index + 1) % var.vm_pool_params.vm_count)} > /tmp/ping.log && echo -n 'pass' > /tmp/ping.result || echo -n 'fail' > /tmp/ping.result"
    ]
    on_failure = continue
  }
}

data "remote_file" "ping_logs" {
  count      = var.vm_pool_params.vm_count
  depends_on = [null_resource.pinger]
  conn {
    user        = var.remote_user
    private_key = file(var.ssh_keys.private_key_path)
    host        = aws_eip.public-eip[count.index].public_ip
  }
  path = "/tmp/ping.log"
}

data "remote_file" "ping_results" {
  count      = var.vm_pool_params.vm_count
  depends_on = [null_resource.pinger]
  conn {
    user        = var.remote_user
    private_key = file(var.ssh_keys.private_key_path)
    host        = aws_eip.public-eip[count.index].public_ip
  }
  path = "/tmp/ping.result"
}