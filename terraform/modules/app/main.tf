resource "google_compute_instance" "app" {
  name = "reddit-app"
  machine_type = "g1-small"
  zone = var.zone
  tags = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = var.app_disk_image
    }
  }
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.app_ip.address
    }
  }
  metadata = {
    ssh-keys = "nluzgin:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "nluzgin"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/files/puma.service"
    destination = var.puma_service_path
  }

  provisioner "file" {
    source      = "${path.module}/files/deploy.sh"
    destination = var.deploy_script_path
  }

  provisioner "remote-exec" {
    inline = [
      "sudo echo DATABASE_URL=${var.db_ip} >> ~/.bashrc ",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${var.deploy_script_path}",
      "sh ${var.deploy_script_path} ${var.puma_service_path}"
    ]
  }
}

resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
}
