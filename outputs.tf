# Outputs
# webservers

# bastion hosts to connect to private subnets

# DNS and endpoint of the DB instance
output "DB DNS" {
	value = "${aws_db_instance.wordpress_db.endpoint}"
}

# ELB endpoint
output "ELB DNS" {
	value = "${aws_elb.wordpress_elb.dns_name}"
}

# EFS Filesystem
output "EFS Filesystem" {
	value = "${aws_efs_file_system.wordpress_efs.dns_name}"
}

output "Cloudfront Distribution Address" {
	value = "${aws_cloudfront_distribution.wordpress_distribution.domain_name}"
}