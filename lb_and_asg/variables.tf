variable "keypair" {
  default = "flawwwless-frankfurt"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "env" {
  default = "blue"
}

variable "min_size" {}

variable "max_size" {}

variable "min_elb_capacity" {}
