provider "digitalocean" {
}

data "digitalocean_image" "pwd_worker_snapshot" {
  name = "packer-hashi-dev-box-ubuntu-1604-v180531-0007"
}

resource "digitalocean_ssh_key" "pwd_ssh" {
  name       = "pwd-ssh"
  public_key = "${file("../ssh/id_rsa.pub")}"
}

resource "digitalocean_volume" "docker_lvm" {
  region      = "${var.region}"
  name        = "docker-lvm"
  size        = 100
  description = "Disk partition for docker direct-lvm"
}

resource "digitalocean_droplet" "pwd_droplet" {
  image  = "${data.digitalocean_image.pwd_worker_snapshot.image}"
  name   = "pwd-node"
  region = "${var.region}"
  size   = "8gb"

  resize_disk = false

  volume_ids = ["${digitalocean_volume.docker_lvm.id}"]

  ssh_keys = [ "${digitalocean_ssh_key.pwd_ssh.id}" ]

  connection {
    user        = "root"
    private_key = "${file("../ssh/id_rsa")}"
  }
}

resource "digitalocean_domain" "pwd_subdomain" {
  name       = "pwd.gokhansengun.com"
  ip_address = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
}

resource "digitalocean_record" "pwd_host_records" {
  domain = "${digitalocean_domain.pwd_subdomain.name}"
  type   = "A"
  name   = "do"
  value  = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
  ttl    = 60
}

resource "digitalocean_record" "pwd_subdomain-records" {
  domain = "${digitalocean_domain.pwd_subdomain.name}"
  type   = "A"
  name   = "*.do"
  value  = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
  ttl    = 60
}

resource "digitalocean_domain" "pwk_subdomain" {
  name       = "pwk.gokhansengun.com"
  ip_address = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
}

resource "digitalocean_record" "pwk_host_records" {
  domain = "${digitalocean_domain.pwk_subdomain.name}"
  type   = "A"
  name   = "do"
  value  = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
  ttl    = 60
}

resource "digitalocean_record" "pwk_subdomain-records" {
  domain = "${digitalocean_domain.pwk_subdomain.name}"
  type   = "A"
  name   = "*.do"
  value  = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
  ttl    = 60
}

resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    worker_droplet_ids = "${join(",", digitalocean_droplet.pwd_droplet.*.id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
    user        = "root"
    private_key = "${file("../ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "../scripts/setup.sh"
    destination = "$HOME/setup.sh"
  }

  provisioner "file" {
    source      = "../scripts/run-app.sh"
    destination = "$HOME/run-app.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/*.sh",
      // "$HOME/setup.sh",
      // "$HOME/run-app.sh",
    ]
  }
}
