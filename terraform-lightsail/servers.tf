resource "aws_lightsail_instance" "hkvpn" {
  name              = var.tag
  bundle_id         = var.bundle_id
  blueprint_id      = var.blueprint_id
  availability_zone = var.zone
  key_pair_name     = aws_lightsail_key_pair.hkvpn.name
}

resource "null_resource" "exec" {
  depends_on = [
    aws_lightsail_instance.hkvpn,
  ]

  provisioner "remote-exec" {
    inline = [
      "sudo apt -qq install python -y",
    ]

    connection {
      agent       = false
      timeout     = var.timeout
      host        = aws_lightsail_static_ip.hkvpn.ip_address
      private_key = file(var.private_key)
      user        = var.username
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 50;
      >inventory.ini;
      echo "[hkvpn]" | tee -a inventory.ini;
      echo "${aws_lightsail_static_ip.hkvpn.ip_address} ansible_user=${var.username} ansible_ssh_private_key_file=${var.private_key}" | tee -a inventory.ini;
      export ANSIBLE_HOST_KEY_CHECKING=False;
      ansible-playbook -u ${var.username} --private-key ${var.private_key} --vault-password-file ${var.vault_password_file} -i inventory.ini ../ansible/playbook.yml
    EOT
  }
}