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

data "ionoscloud_image" "example" {
  name = "ubuntu-22.04"
  type       = "HDD"
  cloud_init = "V1"
  location   = "de/fra"
}

data "ionoscloud_datacenter" "haproxy_dc" {
  name     = "Datacenter HAProrxy Example"
  location = "de/fra"
}

data "ionoscloud_lan" "haproxy_lan" {
  datacenter_id = data.ionoscloud_datacenter.haproxy_dc.id
  name          = "HAProxyLAN"
}

# failover requires reserved IP
resource "ionoscloud_ipblock" "example" {
  location = data.ionoscloud_datacenter.haproxy_dc.location
  size     = 2
  name     = "IP Block Example"
}

resource "ionoscloud_server" "example_A" {
  name              = "Server A"
  datacenter_id     = data.ionoscloud_datacenter.haproxy_dc.id
  cores             = 1
  ram               = 1024
  availability_zone = "ZONE_1"
  cpu_family        = "INTEL_SKYLAKE"
  image_name        = data.ionoscloud_image.example.id
  image_password    = random_password.server_A_image_password.result
  volume {
    name      = "system"
    size      = 14
    disk_type = "SSD"
  }
  nic {
    name            = "NIC A"
    lan             = data.ionoscloud_lan.haproxy_lan.id
    dhcp            = true
    firewall_active = true
    ips             = [ionoscloud_ipblock.example.ips[0], ionoscloud_ipblock.example.ips[1]]
  }
}
resource "random_password" "server_A_image_password" {
  length  = 16
  special = false
}

resource "ionoscloud_ipfailover" "example" {
  depends_on    = [data.ionoscloud_lan.haproxy_lan]
  datacenter_id = data.ionoscloud_datacenter.haproxy_dc.id
  lan_id        = data.ionoscloud_lan.haproxy_lan.id
  ip            = ionoscloud_ipblock.example.ips[0]
  nicuuid       = ionoscloud_server.example_A.primary_nic
}

resource "ionoscloud_server" "example_B" {
  depends_on        = [ionoscloud_ipfailover.example]
  name              = "Server B"
  datacenter_id     = data.ionoscloud_datacenter.haproxy_dc.id
  cores             = 1
  ram               = 1024
  availability_zone = "ZONE_1"
  cpu_family        = "INTEL_SKYLAKE"
  image_name        = data.ionoscloud_image.example.id
  image_password    = random_password.server_B_image_password.result
  volume {
    name      = "system"
    size      = 14
    disk_type = "SSD"
  }
  nic {
    name            = "NIC B"
    lan             = data.ionoscloud_lan.haproxy_lan.id
    dhcp            = true
    firewall_active = true
    ips             = [ionoscloud_ipblock.example.ips[0]]
  }
}

resource "random_password" "server_B_image_password" {
  length  = 16
  special = false
}
