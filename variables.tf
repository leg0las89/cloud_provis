variable "profile" {
  type    = string
  default = "default"
}

variable "region-master" {
  type    = string
  default = "us-east-1"
}

variable "region-worker" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  default = "0.0.0.0/0"

}

variable "workers-count" {
  type    = number
  default = 5
}

variable "instance-type" {
  type    = string
  default = "t3.micro"
}