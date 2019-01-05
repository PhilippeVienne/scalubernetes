data rke_node_parameter "nodes" {
  count   = "${cloudflare_record.node.count}"

  address = "${element(cloudflare_record.node.*.hostname, count.index)}"
  user    = "root"
  role    = ["controlplane", "worker", "etcd"]
  internal_address = "${element(scaleway_server.node.*.private_ip, count.index)}"
  ssh_key = "${tls_private_key.admin_key.private_key_pem}"
}

resource rke_cluster "cluster" {

  nodes_conf = ["${data.rke_node_parameter.nodes.*.json}"]

  ingress = {
    provider = "nginx"
    extra_args = {
      enable-ssl-passthrough = ""
    }
  }

  ignore_docker_version = false

  services_etcd {
    # for etcd snapshots
    snapshot  = true
    retention = "24h"
    creation  = "5m0s"
  }

  services_kube_api {
    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-controller
    service_cluster_ip_range = "192.168.0.0/20"

    # Expose a different port range for NodePort services
    service_node_port_range = "30000-32767"

    pod_security_policy      = false

    # Add additional arguments to the kubernetes API server
    # This WILL OVERRIDE any existing defaults
    extra_args = {
      # Enable audit log to stdout
      audit-log-path = "-"

      # Increase number of delete workers
      delete-collection-workers = 3

      # Set the level of log output to debug-level
      v = 4
    }
  }

  services_kube_controller {
    # CIDR pool used to assign IP addresses to pods in the cluster
    cluster_cidr             = "192.168.16.0/20"

    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-api
    service_cluster_ip_range = "192.168.0.0/20"
  }

  services_scheduler {}

  services_kubelet {
    # Base domain for the cluster
    cluster_domain        = "cluster.local"

    # IP address for the DNS service endpoint
    cluster_dns_server    = "192.168.0.10"

    # Fail if swap is on
    fail_swap_on = false

    # Optionally define additional volume binds to a service
    extra_binds = [
      "/usr/libexec/kubernetes/kubelet-plugins:/usr/libexec/kubernetes/kubelet-plugins",
    ]
  }

  services_kubeproxy {}

  ################################################
  # Authentication
  ################################################
  # Currently, only authentication strategy supported is x509.
  # You can optionally create additional SANs (hostnames or IPs) to add to the API server PKI certificate.
  # This is useful if you want to use a load balancer for the control plane servers.
  authentication {
    strategy = "x509"

    sans = [
      "${scaleway_server.node.*.private_ip}",
      "${scaleway_server.node.*.public_ip}",
      "${cloudflare_record.node.*.hostname}",
    ]
  }

  ################################################
  # Authorization
  ################################################
  # Kubernetes authorization mode
  #   - Use `mode: "rbac"` to enable RBAC
  #   - Use `mode: "none"` to disable authorization
  authorization {
    mode = "rbac"
  }

  # Add-ons are deployed using kubernetes jobs. RKE will give up on trying to get the job status after this timeout in seconds..
  addon_job_timeout = 30

  #########################################################
  # Network(CNI) - supported: flannel/calico/canal/weave
  #########################################################
  # There are several network plug-ins that work, but we default to canal
  network {
    plugin = "canal"
    options {
      canal_flannel_backend_type = "vxlan"
    }
  }


}


resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config.yml"
  content = "${rke_cluster.cluster.kube_config_yaml}"
}

resource "cloudflare_record" "rancher" {
  count = "${scaleway_ip.node.count}"
  domain = "${var.cloudflare_domain}"
  name = "${var.rancher_subdomain}"
  type = "A"
  value = "${element(scaleway_ip.node.*.ip, count.index)}"
}
