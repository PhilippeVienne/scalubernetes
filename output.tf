output "ssh_private_key" {
  value = "${tls_private_key.admin_key.private_key_pem}"
}

output "kube_config" {
  value = "${rke_cluster.cluster.kube_config_yaml}"
}

