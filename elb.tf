# ELB - Classic ELB with sticky session management
resource "aws_elb" "wordpress_elb" {
  name = "wordpress-elb"
  subnets = ["${aws_subnet.wordpress_public_1.id}", "${aws_subnet.wordpress_public_2.id}"]
  security_groups = ["${aws_security_group.wordpress_elb_sg.id}"]
 listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/healthcheck.html"
    interval = 30
  }

  cross_zone_load_balancing = true
  connection_draining = true
  connection_draining_timeout = 400
  tags {
    Name = "wordpress-elb"
  }
}

resource "aws_lb_cookie_stickiness_policy" "wordpress_stickiness_policy" {
  name                     = "wp-stickiness-policy"
  load_balancer            = "${aws_elb.wordpress_elb.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}