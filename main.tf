data "scaleway_image" "ubuntu" {
  architecture = "${var.arch}"
  name         = "Ubuntu Xenial"
}

resource "tls_private_key" "admin_key" {
  algorithm = "RSA"
}

resource "scaleway_ssh_key" "admin_key" {
  key = "${replace(tls_private_key.admin_key.public_key_openssh, "\n", "")}"
}

resource "scaleway_ip" "node" {
  count = "${var.node_count}"
}

resource "cloudflare_record" "node" {
  count = "${scaleway_ip.node.count}"
  domain = "${var.cloudflare_domain}"
  name = "node-${count.index}.${var.subdomain}"
  type = "A"
  value = "${element(scaleway_ip.node.*.ip, count.index)}"
}
resource "scaleway_server" "node" {
  count = "${cloudflare_record.node.count}"
  name  = "${element(cloudflare_record.node.*.hostname, count.index)}"
  image = "${data.scaleway_image.ubuntu.id}"
  type  = "${var.server_type}"
  public_ip = "${element(scaleway_ip.node.*.ip, count.index)}"

  depends_on = ["scaleway_ssh_key.admin_key"]

  connection {
    private_key = "${tls_private_key.admin_key.private_key_pem}"
    host = "${element(cloudflare_record.node.*.value, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://raw.githubusercontent.com/rancher/install-docker/master/${var.docker_version}.sh | bash",
      "service docker start",
      "docker version"
    ]
  }

}
