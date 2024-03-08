////////////////////////////////////////////////////////////////////////////////////////
//                            TERRAFORM PROVIDERS & BACKEND
////////////////////////////////////////////////////////////////////////////////////////
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

terraform {
  backend "gcs" {
    bucket = "thetan-chain-devnet"
    prefix = "tnet-1"
  }
}

provider "google" {
  project = var.google_cloud_project_name
  region  = var.google_cloud_project_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API Token"
}

////////////////////////////////////////////////////////////////////////////////////////
//                                        VARIABLES
////////////////////////////////////////////////////////////////////////////////////////
variable "ethereum_network" {
  type    = string
  default = "dencun-tnet-1"
}

variable "google_cloud_project_name" {
  type = string
}

variable "google_cloud_project_region" {
  type    = string
  default = "asia-southeast1-a"
}

variable "google_ssh_key_name" {
  type    = string
  default = "shared-devops-eth2"
}

variable "regions" {
  default = [
    "asia-southeast1-a",
  ]
}

variable "base_cidr_block" {
  default = "10.92.0.0/16"

}

////////////////////////////////////////////////////////////////////////////////////////
//                                        LOCALS
////////////////////////////////////////////////////////////////////////////////////////

locals {
  vm_groups = [
    var.mev_relay,
    var.bootnode,
    var.lighthouse_geth,
    # var.lighthouse_nethermind,
    var.lighthouse_erigon,
    # var.lighthouse_besu,
    # var.lighthouse_ethereumjs,
    # var.lighthouse_reth,
    var.prysm_geth,
    var.prysm_nethermind,
    var.prysm_erigon,
    # var.prysm_besu,
    # var.prysm_ethereumjs,
    # var.prysm_reth,
    # var.lodestar_geth,
    # var.lodestar_nethermind,
    # var.lodestar_erigon,
    # var.lodestar_besu,
    # var.lodestar_ethereumjs,
    # var.lodestar_reth,
    var.nimbus_geth,
    # var.nimbus_nethermind,
    # var.nimbus_erigon,
    # var.nimbus_besu,
    # var.nimbus_ethereumjs,
    # var.nimbus_reth,
    # var.teku_geth,
    # var.teku_nethermind,
    # var.teku_erigon,
    # var.teku_besu,
    # var.teku_ethereumjs,
    # var.teku_reth,
  ]
}

locals {
  base_cidr_block = var.base_cidr_block
  google_vpcs = {
    for region in var.regions : region => {
      name     = "${var.ethereum_network}-${region}"
      region   = region
      ip_range = cidrsubnet(local.base_cidr_block, 8, index(var.regions, region))
    }
  }
}

locals {
  google_vm_groups = flatten([
    for vm_group in local.vm_groups :
    [
      for i in range(0, vm_group.count) : {
        group_name = "${vm_group.name}"
        id         = "${vm_group.name}-${i + 1}"
        vms = {
          "${i + 1}" = {
            tags   = "group-name--${vm_group.name},val-start--${vm_group.validator_start + (i * (vm_group.validator_end - vm_group.validator_start) / vm_group.count)},val-end--${min(vm_group.validator_start + ((i + 1) * (vm_group.validator_end - vm_group.validator_start) / vm_group.count), vm_group.validator_end)}"
            region = try(vm_group.location, local.google_default_region)
            size   = try(vm_group.size, local.google_default_size)
            ipv6   = try(vm_group.ipv6, false)
          }
        }
      }
    ]
  ])
}

locals {
  google_default_region = "asia-southeast1-a"
  google_default_size   = "n2-standard-2"
  google_default_image  = "debian-cloud/debian-12"
  google_global_tags = [
    "eth-network--${var.ethereum_network}"
  ]

  # flatten vm_groups so that we can use it with for_each()
  google_vms = flatten([
    for group in local.google_vm_groups : [
      for vm_key, vm in group.vms : {
        id        = "${group.id}"
        group_key = "${group.group_name}"
        vm_key    = vm_key

        name = try(vm.name, "${group.id}")
        region       = try(vm.region, try(group.region, local.google_default_region))
        image        = try(vm.image, local.google_default_image)
        size         = try(vm.size, local.google_default_size)
        resize_disk  = try(vm.resize_disk, true)
        monitoring   = try(vm.monitoring, true)
        backups      = try(vm.backups, false)
        ipv6         = try(vm.ipv6, false)
        ansible_vars = try(vm.ansible_vars, null)
        vpc_network_name = try(vm.vpc_network_name, try(
          google_compute_network.main[vm.region].name,
          google_compute_network.main[try(group.region, local.google_default_region)].name
        ))

        tags = concat(local.google_global_tags, try(split(",", group.tags), []), try(split(",", vm.tags), []))
      }
    ]
  ])
}

////////////////////////////////////////////////////////////////////////////////////////
//                                  DIGITALOCEAN RESOURCES
////////////////////////////////////////////////////////////////////////////////////////
# data "digitalocean_project" "main" {
#   name = var.digitalocean_project_name
# }

# resource "tls_private_key" "main" {
#   algorithm = "ED25519"
# }

resource "google_compute_network" "main" {
  for_each = local.google_vpcs

  routing_mode = "REGIONAL"
  name         = each.value["name"]
  # region   = each.value["region"]
  # ip_range = each.value["ip_range"]
}

# resource "digitalocean_vpc" "main" {
#   for_each = local.digitalocean_vpcs

#   name     = each.value["name"]
#   region   = each.value["region"]
#   ip_range = each.value["ip_range"]
# }

data "google_client_openid_userinfo" "me" {}

resource "google_compute_address" "main" {
  for_each = {
    for vm in local.google_vms : "${vm.id}" => vm
  }

  name = "${var.ethereum_network}-${each.value.name}"

  // cut string from "asia-southeast1-a" to "asia-southeast1"
  region = "${join("-", slice(split("-", each.value.region), 0, 2))}"
}

resource "google_compute_instance" "main" {
  for_each = {
    for vm in local.google_vms : "${vm.id}" => vm
  }

  name         = "${var.ethereum_network}-${each.value.name}"
  zone       = each.value.region
  machine_type = each.value.size
  tags         = each.value.tags

  metadata = {
    ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = each.value.image
    }
  }

  network_interface {
    network = each.value.vpc_network_name

    access_config {
      nat_ip = google_compute_address.main[each.key].address
    }
  }
}

resource "google_compute_firewall" "main" {
  for_each = google_compute_network.main

  name          = "${var.ethereum_network}-nodes"
  network       = each.value.name
  target_tags   = [
    "eth-network--${var.ethereum_network}"
  ]

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22","80", "443", "9000-9002", "30303"]
  }

  allow {
    protocol = "udp"
    ports    = ["9000-9002"]
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//                                   DNS NAMES
////////////////////////////////////////////////////////////////////////////////////////

data "cloudflare_zone" "default" {
  name = "giangho.pro"
}

resource "cloudflare_record" "server_record" {
  for_each = {
    for vm in local.google_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "${each.value.name}.${var.ethereum_network}"
  type    = "A"
  value   = google_compute_address.main[each.value.id].address
  proxied = false
  ttl     = 120
}

# resource "cloudflare_record" "server_record6" {
#   for_each = {
#     for vm in local.digitalocean_vms : "${vm.id}" => vm if vm.ipv6
#   }
#   zone_id = data.cloudflare_zone.default.id
#   name    = "${each.value.name}.${var.ethereum_network}"
#   type    = "AAAA"
#   value   = digitalocean_droplet.main[each.value.id].ipv6_address
#   proxied = false
#   ttl     = 120
# }

resource "cloudflare_record" "server_record_rpc" {
  for_each = {
    for vm in local.google_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "rpc.${each.value.name}.${var.ethereum_network}"
  type    = "A"
  value   = google_compute_address.main[each.value.id].address
  proxied = false
  ttl     = 120
}

# resource "cloudflare_record" "server_record_rpc6" {
#   for_each = {
#     for vm in local.digitalocean_vms : "${vm.id}" => vm if vm.ipv6
#   }
#   zone_id = data.cloudflare_zone.default.id
#   name    = "rpc.${each.value.name}.${var.ethereum_network}"
#   type    = "AAAA"
#   value   = digitalocean_droplet.main[each.value.id].ipv6_address
#   proxied = false
#   ttl     = 120
# }

resource "cloudflare_record" "server_record_beacon" {
  for_each = {
    for vm in local.google_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "bn.${each.value.name}.${var.ethereum_network}"
  type    = "A"
  value   = google_compute_address.main[each.value.id].address
  proxied = false
  ttl     = 120
}

# resource "cloudflare_record" "server_record_beacon6" {
#   for_each = {
#     for vm in local.digitalocean_vms : "${vm.id}" => vm if vm.ipv6
#   }
#   zone_id = data.cloudflare_zone.default.id
#   name    = "bn.${each.value.name}.${var.ethereum_network}"
#   type    = "AAAA"
#   value   = digitalocean_droplet.main[each.value.id].ipv6_address
#   proxied = false
#   ttl     = 120
# }

////////////////////////////////////////////////////////////////////////////////////////
//                          GENERATED FILES AND OUTPUTS
////////////////////////////////////////////////////////////////////////////////////////

# resource "local_file" "ansible_inventory" {
#   content = templatefile("ansible_inventory.tmpl",
#     {
#       ethereum_network_name = "${var.ethereum_network}"
#       groups = merge(
#         { for group in local.digitalocean_vm_groups : "${group.group_name}" => true... },
#       )
#       hosts = merge(
#         {
#           for key, server in digitalocean_droplet.main : "do.${key}" => {
#             ip              = "${server.ipv4_address}"
#             ipv6            = try(server.ipv6_address, "none")
#             group           = try(split(":", tolist(server.tags)[2])[1], "unknown")
#             validator_start = try(split(":", tolist(server.tags)[4])[1], 0)
#             validator_end   = try(split(":", tolist(server.tags)[3])[1], 0) # if the tag is not a number it will be 0 - e.g no validator keys
#             tags            = "${server.tags}"
#             hostname        = "${split(".", key)[0]}"
#             cloud           = "digitalocean"
#             region          = "${server.region}"
#           }
#         }
#       )
#     }
#   )
#   filename = "../../ansible/inventories/tnet-1/inventory.ini"
# }


# resource "digitalocean_firewall" "mev_rule" {
#   name        = "${var.ethereum_network}-mev-relay"
#   droplet_ids = [digitalocean_droplet.main["mev-relay-1"].id]
#   // Mev-relay-api
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "9062"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# }

# resource "cloudflare_record" "mev_relay_cloudflare_record" {
#   zone_id = data.cloudflare_zone.default.id
#   name    = "mev-api.${var.ethereum_network}"
#   type    = "A"
#   value   = digitalocean_droplet.main["mev-relay-1"].ipv4_address
#   proxied = false
#   ttl     = 120
# }

# resource "digitalocean_firewall" "mev_rule-web" {
#   name        = "${var.ethereum_network}-mev-relay-web"
#   droplet_ids = [digitalocean_droplet.main["mev-relay-1"].id]
#   // Mev-relay-api
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "9060"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# }
