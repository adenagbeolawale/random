#AUTOSCALING GROUP
resource "aws_launch_configuration" "bastion_launch_config" {
  name_prefix          = "bastion_launch_config"
  image_id             = "${lookup(var.AMIS, var.AWS_REGION)}"
  #image_id             = "${var.AMIS["eu-west-2"]}"
  instance_type        = "${var.EC2_INSTACE_TYPE}"
  key_name             = "${aws_key_pair.ssh_key_pair.key_name}"
  security_groups      = ["${aws_security_group.wordpress_bastion_sg.id}"]
  enable_monitoring = false
  user_data            = <<EOF
  #!/bin/bash
  yum update -y

  EOF

  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion_autoscaling_group" {
  name                 = "bastion_autoscaling_group"
  vpc_zone_identifier  = ["${aws_subnet.wordpress_public_1.id}", "${aws_subnet.wordpress_public_2.id}"]
  launch_configuration = "${aws_launch_configuration.bastion_launch_config.name}"
  min_size             = "2"
  max_size             = "2"
  health_check_grace_period = 300
  health_check_type = "EC2"
  #load_balancers = ["${aws_elb.wordpress_elb.name}"]
  force_delete = true

  tag {
      key = "Name"
      value = "Bastion-EC2"
      propagate_at_launch = true
  }
}