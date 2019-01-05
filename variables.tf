variable "scaleway_organization" {
  type = "string"
  description = "The ID of your targeted scaleway organization, see https://console.scaleway.com/account/credentials"
}

variable "scaleway_token" {
    type = "string"
  description = "Secret token obtained only by generating a new token on https://console.scaleway.com/account/credentials"
}

variable "scaleway_region" {
  default = "par1"
}

variable "cloudflare_api_key" {
  type = "string"
  description = "API Key bound to your Cloudflare Account, see https://dash.cloudflare.com/profile"
}

variable "cloudflare_email" {
  description = "Email bound to your Cloudflare Account"
}

variable "arch" {
  default = "x86_64"
  description = "Archeticture of servers in Scaleway (value must be arm or x86_64)"
}

variable "server_type" {
  default = "START1-S"
  description = "Type of the server to use to build clusters"
}

variable "cloudflare_domain" {
  description = "TLD to use to register DNS"
}

variable "subdomain" {
  default = "infra"
  description = "subdomain for infrastructure records"
}

variable "rancher_subdomain" {
  default = "rancher"
  description = "subdomain to access to Rancher panel"
}

variable "node_count" {
  type = "string"
  default = "3"
  description = "Number of server to add to your cluster"
}

variable "docker_version" {
  default = "17.03.2"
  type = "string"
  description = "Version of Docker to install on the hosts"
}
