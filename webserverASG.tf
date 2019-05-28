#AUTOSCALING GROUP
resource "aws_launch_configuration" "wordpress_launch_config" {
  name_prefix          = "wordpress_launch_config"
  image_id             = "${lookup(var.AMIS, var.AWS_REGION)}"
  #image_id             = "${var.AMIS["eu-west-2"]}"
  instance_type        = "${var.EC2_INSTACE_TYPE}"
  key_name             = "${aws_key_pair.ssh_key_pair.key_name}"
  security_groups      = ["${aws_security_group.wordpress_webserver_sg.id}", "${aws_security_group.wordpress_efs_sg.id}"]
  enable_monitoring = false
  user_data            = <<EOF
#!/bin/bash

yum update -y
yum install -y httpd24 php70 php70-mysqlnd
yum install -y amazon-efs-utils

#mount efs
echo "${aws_efs_file_system.wordpress_efs.dns_name}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab
mount -a -t efs defaults

cd /var/www/html

# first member of the cluster will perform this step
if [ ! -f "/var/www/html/healthcheck.html" ]; then

#ELB health check file
echo "I am healthy" > /var/www/html/healthcheck.html

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf latest.tar.gz

fi

#set permissions
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www

chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

#ensure httpd starts up after reboot
chkconfig httpd on

#start the httpd
service httpd start
  EOF
  
  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wordpress_autoscaling_group" {
  name                 = "wordpress_autoscaling_group"
  vpc_zone_identifier  = ["${aws_subnet.wordpress_private_1.id}", "${aws_subnet.wordpress_private_2.id}"]
  launch_configuration = "${aws_launch_configuration.wordpress_launch_config.name}"
  min_size             = "${var.AUTOSCALING_MIN_SIZE}"
  max_size             = "${var.AUTOSCALING_MAX_SIZE}"
  health_check_grace_period = 300
  health_check_type = "ELB"
  load_balancers = ["${aws_elb.wordpress_elb.name}"]
  force_delete = true

  tag {
      key = "Name"
      value = "Webserver-EC2"
      propagate_at_launch = true
  }
  
  depends_on = ["aws_efs_mount_target.wordpress_mount_target1", "aws_efs_mount_target.wordpress_mount_target2", "aws_db_instance.wordpress_db"]
}

#AUTOSCALING POLICY
# scale up alarm
resource "aws_autoscaling_policy" "wordpress_cpu_policy" {
  name                   = "wordpress_cpu_policy"
  autoscaling_group_name = "${aws_autoscaling_group.wordpress_autoscaling_group.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "600"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "wordpress_cpu_alarm" {
  alarm_name          = "wordpress_cpu_alarm"
  alarm_description   = "wordpress_cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "600"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wordpress_autoscaling_group.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.wordpress_cpu_policy.arn}"]
}

# scale down alarm
resource "aws_autoscaling_policy" "wordpress_cpu_policy_scaledown" {
  name                   = "wordpress_cpu_policy_scaledown"
  autoscaling_group_name = "${aws_autoscaling_group.wordpress_autoscaling_group.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "600"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "wordpress_cpu_alarm_scaledown" {
  alarm_name          = "wordpress_cpu_alarm_scaledown"
  alarm_description   = "wordpress_cpu_alarm_scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "600"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wordpress_autoscaling_group.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.wordpress_cpu_policy_scaledown.arn}"]
}