output "linux_public_ip" {
  value = "${module.linux_web.public_ip}"
}

output "windows_public_ip" {
  value = "${module.windows_web.public_ip}"
}

output "web_elb_dns" {
  value = "${aws_elb.web_elb.dns_name}"
}
