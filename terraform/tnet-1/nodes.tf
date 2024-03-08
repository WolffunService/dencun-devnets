# mev-relay
variable "mev_relay" {
  default = {
    name            = "mev-relay"
    count           = 1
    validator_start = 0
    validator_end   = 0
    size            = "n2-standard-4"
  }
}

# Bootnode
variable "bootnode" {
  default = {
    name            = "bootnode"
    count           = 1
    validator_start = 0
    validator_end   = 0
    location        = "asia-southeast1-a"
    size            = "n2-standard-4"
  }
}

# Lighthouse
variable "lighthouse_geth" {
  default = {
    name            = "lighthouse-geth"
    count           = 1
    validator_start = 0
    validator_end   = 100
    location        = "asia-southeast1-a"
    ipv6            = true
  }
}

variable "lighthouse_nethermind" {
  default = {
    name            = "lighthouse-nethermind"
    count           = 1
    validator_start = 100
    validator_end   = 200
    location        = "asia-southeast1-b"
  }
}

variable "lighthouse_besu" {
  default = {
    name            = "lighthouse-besu"
    count           = 1
    validator_start = 200
    validator_end   = 225
    location        = "asia-southeast1-c"
  }
}

variable "lighthouse_erigon" {
  default = {
    name            = "lighthouse-erigon"
    count           = 1
    validator_start = 225
    validator_end   = 250
    location        = "asia-southeast1-a"
  }
}

variable "lighthouse_ethereumjs" {
  default = {
    name            = "lighthouse-ethereumjs"
    count           = 0
    validator_start = 0
    validator_end   = 0
  }
}

# Prysm
variable "prysm_geth" {
  default = {
    name            = "prysm-geth"
    count           = 1
    validator_start = 2855
    validator_end   = 2950
    location        = "asia-southeast1-b"
  }
}

variable "prysm_nethermind" {
  default = {
    name            = "prysm-nethermind"
    count           = 1
    validator_start = 2950
    validator_end   = 3050
    location        = "asia-southeast1-b"
  }
}

variable "prysm_besu" {
  default = {
    name            = "prysm-besu"
    count           = 1
    validator_start = 3050
    validator_end   = 3150
    location        = "asia-southeast1-a"
  }
}

variable "prysm_erigon" {
  default = {
    name            = "prysm-erigon"
    count           = 1
    validator_start = 3150
    validator_end   = 3250
    location        = "asia-southeast1-c"
  }
}

variable "prysm_ethereumjs" {
  default = {
    name            = "prysm-ethereumjs"
    count           = 0
    validator_start = 0
    validator_end   = 0
  }
}

# Lodestar
variable "lodestar_geth" {
  default = {
    name            = "lodestar-geth"
    count           = 1
    validator_start = 510
    validator_end   = 620
    location        = "asia-southeast1-a"
    ipv6            = true
  }
}

variable "lodestar_nethermind" {
  default = {
    name            = "lodestar-nethermind"
    count           = 1
    validator_start = 620
    validator_end   = 720
    location        = "asia-southeast1-c"
  }
}

variable "lodestar_besu" {
  default = {
    name            = "lodestar-besu"
    count           = 1
    validator_start = 720
    validator_end   = 745
    location        = "asia-southeast1-a"
  }
}

variable "lodestar_erigon" {
  default = {
    name            = "lodestar-erigon"
    count           = 1
    validator_start = 745
    validator_end   = 770
    location        = "asia-southeast1-b"
  }
}

variable "lodestar_ethereumjs" {
  default = {
    name            = "lodestar-ethereumjs"
    count           = 1
    validator_start = 770
    validator_end   = 780
    location        = "asia-southeast1-b"
  }
}

# Teku
variable "teku_geth" {
  default = {
    name            = "teku-geth"
    count           = 1
    validator_start = 780
    validator_end   = 880
    location        = "asia-southeast1-a"
  }
}

variable "teku_nethermind" {
  default = {
    name            = "teku-nethermind"
    count           = 1
    validator_start = 880
    validator_end   = 980
    location        = "asia-southeast1-c"
  }
}

variable "teku_besu" {
  default = {
    name            = "teku-besu"
    count           = 1
    validator_start = 980
    validator_end   = 1005
    location        = "asia-southeast1-a"
  }
}

variable "teku_erigon" {
  default = {
    name            = "teku-erigon"
    count           = 1
    validator_start = 1005
    validator_end   = 1030
    location        = "asia-southeast1-b"
  }
}

variable "teku_ethereumjs" {
  default = {
    name            = "teku-ethereumjs"
    count           = 0
    validator_start = 0
    validator_end   = 0
  }
}

# Nimbus
variable "nimbus_geth" {
  default = {
    name            = "nimbus-geth"
    count           = 1
    validator_start = 1030
    validator_end   = 1140
    location        = "asia-southeast1-b"
  }
}

variable "nimbus_nethermind" {
  default = {
    name            = "nimbus-nethermind"
    count           = 1
    validator_start = 1140
    validator_end   = 1240
    location        = "asia-southeast1-a"
  }
}

variable "nimbus_besu" {
  default = {
    name            = "nimbus-besu"
    count           = 1
    validator_start = 1240
    validator_end   = 1265
    location        = "asia-southeast1-c"
  }
}

variable "nimbus_erigon" {
  default = {
    name            = "nimbus-erigon"
    count           = 1
    validator_start = 1265
    validator_end   = 1290
    location        = "asia-southeast1-a"
  }
}

variable "nimbus_ethereumjs" {
  default = {
    name            = "nimbus-ethereumjs"
    count           = 0
    validator_start = 0
    validator_end   = 0
  }
}

# Reth
variable "lighthouse_reth" {
  default = {
    name            = "lighthouse-reth"
    count           = 1
    validator_start = 1290
    validator_end   = 1450
    location        = "asia-southeast1-b"
  }
}

variable "prysm_reth" {
  default = {
    name            = "prysm-reth"
    count           = 1
    validator_start = 3250
    validator_end   = 3350
    location        = "asia-southeast1-b"
  }
}

variable "lodestar_reth" {
  default = {
    name            = "lodestar-reth"
    count           = 1
    validator_start = 1450
    validator_end   = 1600
    location        = "asia-southeast1-a"
  }
}

variable "teku_reth" {
  default = {
    name            = "teku-reth"
    count           = 1
    validator_start = 1600
    validator_end   = 1700
    location        = "asia-southeast1-c"
  }
}

variable "nimbus_reth" {
  default = {
    name            = "nimbus-reth"
    count           = 1
    validator_start = 1700
    validator_end   = 1800
    location        = "asia-southeast1-a"
  }
}
