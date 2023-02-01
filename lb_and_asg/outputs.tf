output "env_1_instances" {
  value = aws_elb.petclinic_elb.instances
}

output "dns_name_env_1" {
  value = aws_elb.petclinic_elb.dns_name
}
