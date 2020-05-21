# The EC2 instance
output "EC2 IP address" {
  value = "${aws_instance.drupal.public_ip}"
}

output "EC2 DNS name" {
  value = "${aws_instance.drupal.public_dns}"
}

# The RDS instance
output "db_instance_id" {
  value = "${aws_db_instance.drupal.id}"
}
output "db_instance_address" {
  value = "${aws_db_instance.drupal.address}"
}
