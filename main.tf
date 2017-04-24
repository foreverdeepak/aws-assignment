provider "aws" {
  region = "${var.aws_region}"
}

module "key_pair" {
  source          = "github.com/opstree-terraform/key_pair"
  public_key_path = "${var.pub_key_path}"
  name            = "${var.vpc_name}-key"
}

module "vpc" {
  source            = "github.com/opstree-terraform/vpc"
  cidr              = "${var.vpc_cidr}"
  name              = "${var.vpc_name}"
  route53_zone_name = "${var.route53_zone_name}"
}

module "pub_subnet_aza" {
  source                  = "github.com/opstree-terraform/subnet"
  vpc_id                  = "${module.vpc.id}"
  cidr                    = "${var.pub_subnet_aza_cidr}"
  az                      = "${var.aws_region}a"
  map_public_ip_on_launch = "true"
  name                    = "${var.vpc_name}-pub_subnet_aza"
}

module "vpc_pvt_rtb_aza" {
  source    = "github.com/opstree-terraform/pvt_route_table"
  pub_sn_id = "${module.pub_subnet_aza.id}"
  vpc_name  = "${var.vpc_name}"
  vpc_id    = "${module.vpc.id}"
}

module "pub_subnet_azb" {
  source                  = "github.com/opstree-terraform/subnet"
  vpc_id                  = "${module.vpc.id}"
  cidr                    = "${var.pub_subnet_azb_cidr}"
  az                      = "${var.aws_region}b"
  map_public_ip_on_launch = "true"
  name                    = "${var.vpc_name}-pub_subnet_azb"
}

module "vpc_pvt_rtb_azb" {
  source    = "github.com/opstree-terraform/pvt_route_table"
  pub_sn_id = "${module.pub_subnet_azb.id}"
  vpc_name  = "${var.vpc_name}"
  vpc_id    = "${module.vpc.id}"
}

module "web_subnet_aza" {
  source             = "github.com/opstree-terraform/private_subnet"
  vpc_id             = "${module.vpc.id}"
  cidr               = "${var.web_subnet_aza_cidr}"
  az                 = "${var.aws_region}a"
  name               = "${var.vpc_name}-web_subnet_aza"
  pvt_route_table_id = "${module.vpc_pvt_rtb_aza.route_table_id}"
}

module "web_subnet_azb" {
  source             = "github.com/opstree-terraform/private_subnet"
  vpc_id             = "${module.vpc.id}"
  cidr               = "${var.web_subnet_azb_cidr}"
  az                 = "${var.aws_region}b"
  name               = "${var.vpc_name}-web_subnet_azb"
  pvt_route_table_id = "${module.vpc_pvt_rtb_azb.route_table_id}"
}

module "pub_ssh_sg" {
  source = "github.com/opstree-terraform/pub_ssh_sg"
  vpc_id = "${module.vpc.id}"
}

module "pub_http_sg" {
  source = "github.com/opstree-terraform/pub_web_sg"
  vpc_id = "${module.vpc.id}"
}

data "template_file" "linux_bootstrap" {
  template = "${file("${path.module}/linux_bootstrap.tpl")}"
}

module "linux_web" {
  source             = "github.com/opstree-terraform/ec2"
  subnet_id          = "${module.pub_subnet_aza.id}"
  name               = "linux-web.${var.route53_zone_name}"
  key_pair_id        = "${module.key_pair.id}"
  aws_region         = "${var.aws_region}"
  aws_region_os      = "${var.aws_region}-centos"
  security_group_ids = ["${module.vpc.default_sg_id}", "${module.pub_ssh_sg.id}", "${module.pub_http_sg.id}"]
  type               = "t2.micro"
  zone_id            = "${module.vpc.zone_id}"
  user_data          = "${data.template_file.linux_bootstrap.rendered}"
  root_volume_size   = "8"
}

data "template_file" "windows_bootstrap" {
  template = "${file("${path.module}/windows_bootstrap.tpl")}"
}

module "linux_web_data_volume" {
  source            = "github.com/opstree-terraform/ebs_volume"
  device_name       = "/dev/sdb"
  aws_instance_id   = "${module.linux_web.id}"
  availability_zone = "${var.aws_region}a"
}

module "windows_web" {
  source             = "github.com/opstree-terraform/ec2"
  subnet_id          = "${module.pub_subnet_azb.id}"
  name               = "windows-web.${var.route53_zone_name}"
  key_pair_id        = "${module.key_pair.id}"
  aws_region_os      = "${var.aws_region}-windows"
  aws_region         = "${var.aws_region}"
  security_group_ids = ["${module.vpc.default_sg_id}", "${module.pub_ssh_sg.id}", "${module.pub_http_sg.id}"]
  type               = "t2.micro"
  zone_id            = "${module.vpc.zone_id}"
  user_data          = ""
  root_volume_size   = "30"
}

module "windows_web_data_volume" {
  source            = "github.com/opstree-terraform/ebs_volume"
  device_name       = "/dev/sdb"
  aws_instance_id   = "${module.windows_web.id}"
  availability_zone = "${var.aws_region}b"
}

resource "aws_elb" "web_elb" {
  name            = "web-elb"
  subnets         = ["${module.pub_subnet_aza.id}", "${module.pub_subnet_azb.id}"]
  security_groups = ["${module.vpc.default_sg_id}", "${module.pub_http_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${module.linux_web.id}", "${module.windows_web.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "web-elb"
  }
}
