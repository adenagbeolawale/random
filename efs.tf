# EFS - for storing web server files
# https://ops.tips/gists/how-aws-efs-multiple-availability-zones-terraform/
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "WordPress_EFS"
 
  tags {
    Name = "WordPress_EFS"
  }
}
 
resource "aws_efs_mount_target" "wordpress_mount_target1" {
  file_system_id = "${aws_efs_file_system.wordpress_efs.id}"
  subnet_id = "${aws_subnet.wordpress_private_1.id}"
  security_groups = ["${aws_security_group.wordpress_efs_sg.id}"]
}

resource "aws_efs_mount_target" "wordpress_mount_target2" {
  file_system_id = "${aws_efs_file_system.wordpress_efs.id}"
  subnet_id = "${aws_subnet.wordpress_private_2.id}"
  security_groups = ["${aws_security_group.wordpress_efs_sg.id}"]
}