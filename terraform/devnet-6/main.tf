////////////////////////////////////////////////////////////////////////////////////////
//                            TERRAFORM PROVIDERS & BACKEND
////////////////////////////////////////////////////////////////////////////////////////
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

terraform {
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    endpoint                    = "https://fra1.digitaloceanspaces.com"
    region                      = "us-east-1"
    bucket                      = "merge-testnets"
    key                         = "infrastructure/4844-devnet-6/terraform.tfstate"
  }
}

provider "digitalocean" {
  http_retry_max = 20
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
  default = "4844-devnet-6"
}

variable "digitalocean_project_name" {
  type    = string
  default = "4844 Testnets"
}

variable "digitalocean_ssh_key_name" {
  type    = string
  default = "shared-devops-eth2"
}

variable "digitalocean_vpcs" {
  type = map(any)
  default = {
    "ams3" = {
      ip_range = "10.48.47.0/24"
    }
  }
}

variable "digitalocean_vm_groups" {
  type = list(any)
  default = [
    {
      id = "bootnode"
      vms = {
        "1" = { size = "s-4vcpu-8gb-amd" }
      }
    },
    # Lodestar
    {
      id = "lodestar-besu"
      vms = {
        "1" = { ansible_vars : "validator_start=0 validator_end=25" }
      },
    },
    {
      id = "lodestar-nethermind"
      vms = {
        "1" = { ansible_vars : "validator_start=25 validator_end=225" }
      },
    },
    {
      id = "lodestar-ethereumjs"
      vms = {
        "1" = { ansible_vars : "validator_start=225 validator_end=250" }
      },
    },
    {
      id = "lodestar-geth"
      vms = {
        "1" = { ansible_vars : "validator_start=250 validator_end=450" }
      },
    },
    # Teku
    {
      id = "teku-besu"
      vms = {
        "1" = { ansible_vars : "validator_start=450 validator_end=475" }
      },
    },
    {
      id = "teku-nethermind"
      vms = {
        "1" = { ansible_vars : "validator_start=475 validator_end=675" }
      },
    },
    {
      id = "teku-ethereumjs"
      vms = {
        "1" = { ansible_vars : "validator_start=675 validator_end=700" }
      },
    },
    {
      id = "teku-geth"
      vms = {
        "1" = { ansible_vars : "validator_start=700 validator_end=900" }
      },
    },
    # Lighthouse
    {
      id = "lighthouse-besu"
      vms = {
        "1" = { ansible_vars : "validator_start=900 validator_end=925" }
      },
    },
    {
      id = "lighthouse-nethermind"
      vms = {
        "1" = { ansible_vars : "validator_start=925 validator_end=1125" }
      },
    },
    {
      id = "lighthouse-ethereumjs"
      vms = {
        "1" = { ansible_vars : "validator_start=1125 validator_end=1150" }
      },
    },
    {
      id = "lighthouse-geth"
      vms = {
        "1" = { ansible_vars : "validator_start=1150 validator_end=1350" }
      },
    },
    # Nimbus
    {
      id = "nimbus-besu"
      vms = {
        "1" = { ansible_vars : "validator_start=1350 validator_end=1375" }
      },
    },
    {
      id = "nimbus-nethermind"
      vms = {
        "1" = { ansible_vars : "validator_start=1375 validator_end=1400" }
      },
    },
    {
      id = "nimbus-ethereumjs"
      vms = {
        "1" = { ansible_vars : "validator_start=1400 validator_end=1425" }
      },
    },
    {
      id = "nimbus-geth"
      vms = {
        "1" = { ansible_vars : "validator_start=1425 validator_end=1450" }
      },
    },
    # Prysm
    {
      id = "prysm-besu"
      vms = {
        "1" = { ansible_vars : "validator_start=1450 validator_end=1475" }
      },
    },
    {
      id = "prysm-nethermind"
      vms = {
        "1" = { ansible_vars : "validator_start=1475 validator_end=1500" }
      },
    },
    {
      id = "prysm-ethereumjs"
      vms = {
        "1" = { ansible_vars : "validator_start=1500 validator_end=1525" }
      },
    },
    {
      id = "prysm-geth"
      vms = {
        "1" = { ansible_vars : "validator_start=1525 validator_end=1550" }
      },
    },
  ]
}

////////////////////////////////////////////////////////////////////////////////////////
//                                        LOCALS
////////////////////////////////////////////////////////////////////////////////////////


locals {
  digitalocean_default_region = "ams3"
  digitalocean_default_size   = "s-2vcpu-4gb-amd"
  digitalocean_default_image  = "debian-11-x64"
  digitalocean_global_tags = [
    "Owner:Devops",
    "EthNetwork:${var.ethereum_network}"
  ]

  # flatten vm_groups so that we can use it with for_each()
  digitalocean_vms = flatten([
    for group in var.digitalocean_vm_groups : [
      for vm_key, vm in group.vms : {
        id        = "${group.id}.${vm_key}"
        group_key = group.id
        vm_key    = vm_key

        name        = try(vm.name, "${group.id}-${vm_key}")
        ssh_keys    = try(vm.ssh_keys, [data.digitalocean_ssh_key.main.fingerprint])
        region      = try(vm.region, try(group.region, local.digitalocean_default_region))
        image       = try(vm.image, local.digitalocean_default_image)
        size        = try(vm.size, local.digitalocean_default_size)
        resize_disk = try(vm.resize_disk, true)
        monitoring  = try(vm.monitoring, true)
        backups     = try(vm.backups, false)
        ipv6        = try(vm.ipv6, false)
        vpc_uuid = try(vm.vpc_uuid, try(
          digitalocean_vpc.main[vm.region].id,
          digitalocean_vpc.main[try(group.region, local.digitalocean_default_region)].id
        ))

        tags = concat(local.digitalocean_global_tags, try(split(",", group.tags), []), try(split(",", vm.tags), []))
      }
    ]
  ])

}

////////////////////////////////////////////////////////////////////////////////////////
//                                  DIGITALOCEAN RESOURCES
////////////////////////////////////////////////////////////////////////////////////////
data "digitalocean_project" "main" {
  name = var.digitalocean_project_name
}

data "digitalocean_ssh_key" "main" {
  name = var.digitalocean_ssh_key_name
}

resource "digitalocean_vpc" "main" {
  for_each = var.digitalocean_vpcs
  name     = try(each.value.name, "${var.ethereum_network}-${each.key}")
  region   = each.key
  ip_range = each.value.ip_range
}

resource "digitalocean_droplet" "main" {
  for_each = {
    for vm in local.digitalocean_vms : "${vm.id}" => vm
  }
  name        = each.value.name
  region      = each.value.region
  ssh_keys    = each.value.ssh_keys
  image       = each.value.image
  size        = each.value.size
  resize_disk = each.value.resize_disk
  monitoring  = each.value.monitoring
  backups     = each.value.backups
  ipv6        = each.value.ipv6
  vpc_uuid    = each.value.vpc_uuid
  tags        = each.value.tags
}

resource "digitalocean_project_resources" "droplets" {
  for_each  = digitalocean_droplet.main
  project   = data.digitalocean_project.main.id
  resources = [each.value.urn]
}

resource "digitalocean_firewall" "main" {
  name = "${var.ethereum_network}-nodes"
  // Tags are used to select which droplets should
  // be assigned to this firewall.
  tags = [
    "EthNetwork:${var.ethereum_network}"
  ]

  // SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  // Nginx / Web
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  // Consensus layer p2p port
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9000-9001"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "udp"
    port_range       = "9000-9001"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  // Execution layer p2p Port
  inbound_rule {
    protocol         = "tcp"
    port_range       = "30303"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "udp"
    port_range       = "30303"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # // Inbound rule for beaconchain explorer
  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "8080"
  #   source_addresses = ["0.0.0.0/0", "::/0"]
  # }

  // Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//                                   DNS NAMES
////////////////////////////////////////////////////////////////////////////////////////

data "cloudflare_zone" "default" {
  name = "ethpandaops.io"
}

resource "cloudflare_record" "server_record" {
  for_each = {
    for vm in local.digitalocean_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "${each.value.name}.srv.${var.ethereum_network}"
  type    = "A"
  value   = digitalocean_droplet.main[each.value.id].ipv4_address
  proxied = false
  ttl     = 120
}

resource "cloudflare_record" "server_record_rpc" {
  for_each = {
    for vm in local.digitalocean_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "rpc.${each.value.name}.srv.${var.ethereum_network}"
  type    = "A"
  value   = digitalocean_droplet.main[each.value.id].ipv4_address
  proxied = false
  ttl     = 120
}

resource "cloudflare_record" "server_record_beacon" {
  for_each = {
    for vm in local.digitalocean_vms : "${vm.id}" => vm
  }
  zone_id = data.cloudflare_zone.default.id
  name    = "bn.${each.value.name}.srv.${var.ethereum_network}"
  type    = "A"
  value   = digitalocean_droplet.main[each.value.id].ipv4_address
  proxied = false
  ttl     = 120
}

# resource "cloudflare_record" "beaconchain_record" {
#   zone_id = data.cloudflare_zone.default.id
#   name    = "beaconchain.${var.ethereum_network}"
#   type    = "A"
#   value   = digitalocean_droplet.main["lighthouse-erigon.1"].ipv4_address
#   proxied = true
#   ttl     = 1
# }


////////////////////////////////////////////////////////////////////////////////////////
//                          GENERATED FILES AND OUTPUTS
////////////////////////////////////////////////////////////////////////////////////////

resource "local_file" "ansible_inventory" {
  content = templatefile("ansible_inventory.tmpl",
    {
      ethereum_network_name = "${var.ethereum_network}"
      groups = merge(
        { for group in var.digitalocean_vm_groups : "${group.id}" => true },
      )
      hosts = merge(
        {
          for key, server in digitalocean_droplet.main : "do.${key}" => {
            ip       = "${server.ipv4_address}"
            group    = split(".", key)[0]
            tags     = "${server.tags}"
            hostname = "${split(".", key)[0]}-${split(".", key)[1]}"
            cloud    = "digitalocean"
            region   = "${server.region}"
            ansible_vars = try(
              var.digitalocean_vm_groups[
                index([for v in var.digitalocean_vm_groups : v.id], split(".", key)[0])
              ].vms[split(".", key)[1]].ansible_vars
            , null)
          }
        }
      )
    }
  )
  filename = "../../ansible/inventories/devnet-6/inventory.ini"
}
