output "worker-ips" {
    value = "${digitalocean_droplet.pwd_droplet.ipv4_address}"
}
