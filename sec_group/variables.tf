variable "ingress_ports" {
  default = [
    "80",
    "443",
    "22"
  ]
}

variable "vpc_id" {}
