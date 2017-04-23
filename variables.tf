variable "aws_region" {
  default = "ap-south-1"
}

variable "pub_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "vpc_name" {
  default = "sandy-test"
}

variable "vpc_cidr" {
  default = "18.0.0.0/16"
}

variable "route53_zone_name" {
  default = "internal.amazon.com"
}

variable "pub_subnet_aza_cidr" {
  default = "18.0.0.0/24"
}

variable "pub_subnet_azb_cidr" {
  default = "18.0.1.0/24"
}

variable "web_subnet_aza_cidr" {
  default = "18.0.2.0/24"
}

variable "web_subnet_azb_cidr" {
  default = "18.0.3.0/24"
}
