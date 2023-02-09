variable "keypair" {
  default = "flawwwless-frankfurt"
}

variable "instance_type" {
  default = "t3.nano"
}

variable "env" {
  default = "env1"
}

variable "status" {
  default = "Clean"
}
variable "min_size" {}

variable "max_size" {}

variable "min_elb_capacity" {}
