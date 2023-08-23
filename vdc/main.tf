terraform {
  required_version = "> 1.0.0"
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "6.4.7"
    }
  }
}

provider "ionoscloud" {}

resource "ionoscloud_datacenter" "haproxy_example" {
  name                = "Datacenter HAProrxy Example"
  location            = "de/fra"
  description         = "HAProxy Example DataCenter"
  sec_auth_protection = false
}

resource "ionoscloud_lan" "haproxy_example" {
  datacenter_id = ionoscloud_datacenter.haproxy_example.id
  public        = true
  name          = "HAProxyLAN"
}

output "datacenter_id" {
  value = ionoscloud_datacenter.haproxy_example.id
}

output "lan_id" {
  value = ionoscloud_lan.haproxy_example.id
}
