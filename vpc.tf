# VPC

resource "aws_vpc" "wordpress_vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "wordpress_vpc"
    }
}

# Subnets
resource "aws_subnet" "wordpress_public_1" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-2a"

    tags {
        Name = "wordpress_public_1_eu-west-2a"
    }
}
resource "aws_subnet" "wordpress_public_2" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-2b"

    tags {
        Name = "wordpress_public_2_eu-west-2b"
    }
}

resource "aws_subnet" "wordpress_private_1" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "eu-west-2a"

    tags {
        Name = "wordpress_private_1_eu-west-2a"
    }
}
resource "aws_subnet" "wordpress_private_2" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "eu-west-2b"

    tags {
        Name = "wordpress_private_2_eu-west-2b"
    }
}

# Internet GW
resource "aws_internet_gateway" "wordpress_gw" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"

    tags {
        Name = "wordpress_gw"
    }
}

resource "aws_eip" "wordpress_eip" {
	vpc = true
}

# NAT GW
resource "aws_nat_gateway" "wordpress_nat" {
    
	depends_on = ["aws_internet_gateway.wordpress_gw"]
	allocation_id = "${aws_eip.wordpress_eip.id}"
	subnet_id     = "${aws_subnet.wordpress_public_1.id}"

    tags {
        Name = "wordpress_nat"
    }
}

# route tables
resource "aws_route_table" "route_igw" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.wordpress_gw.id}"
    }

    tags {
        Name = "route_igw"
    }
}

resource "aws_route_table" "route_nat" {
    vpc_id = "${aws_vpc.wordpress_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.wordpress_nat.id}"
    }

    tags {
        Name = "route_nat"
    }
}

# route associations public
resource "aws_route_table_association" "wordpress_public_1_assoc" {
    subnet_id = "${aws_subnet.wordpress_public_1.id}"
    route_table_id = "${aws_route_table.route_igw.id}"
}
resource "aws_route_table_association" "wordpress_public_2_assoc" {
    subnet_id = "${aws_subnet.wordpress_public_2.id}"
    route_table_id = "${aws_route_table.route_igw.id}"
}

# route associations private
resource "aws_route_table_association" "wordpress_private_1_assoc" {
    subnet_id = "${aws_subnet.wordpress_private_1.id}"
    route_table_id = "${aws_route_table.route_nat.id}"
}
resource "aws_route_table_association" "wordpress_private_2_assoc" {
    subnet_id = "${aws_subnet.wordpress_private_2.id}"
    route_table_id = "${aws_route_table.route_nat.id}"
}

# NACL
# default NACL - deny everything and bring it under management
resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.wordpress_vpc.default_network_acl_id}"
	# no rules set so deny everything
}

# webservers - public subnet
resource "aws_network_acl" "wordpress_public_nacl" {
  vpc_id = "${aws_vpc.wordpress_vpc.id}"
  subnet_ids = ["${aws_subnet.wordpress_public_1.id}", "${aws_subnet.wordpress_public_2.id}"]
  #subnet_ids = ["${aws_subnet.wordpress_public.*.id}"]
  
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "${var.SSH_IP_RANGE}"
    from_port  = 22
    to_port    = 22
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0" 
    from_port  = 1024
    to_port    = 65535
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.3.0/24" # cidr blocks for private subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "10.0.4.0/24" # cidr blocks for private subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "10.0.3.0/24" # cidr blocks for private subnet
    from_port  = 22
    to_port    = 22
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 600
    action     = "allow"
    cidr_block = "10.0.4.0/24" # cidr blocks for private subnet
    from_port  = 22
    to_port    = 22
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 700
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "wordpress_public_nacl"
  }
}

# DB servers - private subnet
resource "aws_network_acl" "wordpress_private_nacl" {
  vpc_id = "${aws_vpc.wordpress_vpc.id}"
  subnet_ids = ["${aws_subnet.wordpress_private_1.id}", "${aws_subnet.wordpress_private_2.id}"]
  #subnet_ids = ["${aws_subnet.wordpress_private.*.id}"]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24" # cidr blocks for public subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.2.0/24" # cidr blocks for public subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.3.0/24" # cidr blocks for private subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "10.0.4.0/24" # cidr blocks for private subnet
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "10.0.1.0/24" # from any bastion host on the public subnet
    from_port  = 22
    to_port    = 22
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 600
    action     = "allow"
    cidr_block = "10.0.2.0/24" # from any bastion host on the public subnet
    from_port  = 22
    to_port    = 22
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 700
    action     = "allow"
    cidr_block = "10.0.1.0/24" # cidr blocks for public subnet
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 800
    action     = "allow"
    cidr_block = "10.0.2.0/24" # cidr blocks for public subnet
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 900
    action     = "allow"
    cidr_block = "10.0.1.0/24" # cidr blocks for public subnet
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 1000
    action     = "allow"
    cidr_block = "10.0.2.0/24" # cidr blocks for public subnet
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 1100
    action     = "allow"
    cidr_block = "0.0.0.0/0" 
    from_port  = 1024
    to_port    = 65535
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
	
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.1.0/24" # cidr blocks for public subnet
    from_port  = 1024
    to_port    = 65535
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "10.0.2.0/24" # cidr blocks for public subnet
    from_port  = 1024
    to_port    = 65535
  }
  
  tags = {
    Name = "wordpress_private_nacl"
  }
}

# Security Groups
# bastion - public subnet
resource "aws_security_group" "wordpress_bastion_sg" {
  name = "wordpress_bastion_sg"
  description = "Securty Group for Bastion in the public subnet"
  vpc_id = "${aws_vpc.wordpress_vpc.id}"
  
  ingress {
    protocol   = "tcp"
    cidr_blocks = ["${var.SSH_IP_RANGE}"]
    from_port  = 22
    to_port    = 22
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"] # cidr blocks for private subnet
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "wordpress_bastion_sg"
  }
}


resource "aws_security_group" "wordpress_elb_sg" {
  name = "wordpress_elb_sg"
  description = "Securty Group for the ELB in the public subnet"
  vpc_id = "${aws_vpc.wordpress_vpc.id}"
  
  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"] # cidr blocks for private subnet
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"] # cidr blocks for private subnet
    from_port  = 443
    to_port    = 443
  }
  
  tags = {
    Name = "wordpress_elb_sg"
  }
}

# Webservers in private subnet
resource "aws_security_group" "wordpress_webserver_sg" {
  name = "wordpress_webserver_sg"
  description = "Securty Group for the DB servers in the private subnet"
  vpc_id = "${aws_vpc.wordpress_vpc.id}"

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"] # cidr blocks for public subnet (should be only from the bastion host)
    from_port  = 22
    to_port    = 22
  }
  
  ingress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    from_port  = "${var.DB_PORT}"
    to_port    = "${var.DB_PORT}"
    protocol   = "tcp"
    security_groups = ["${aws_security_group.wordpress_db_sg.id}"] # db security group
  }
  
  tags = {
    Name = "wordpress_webserver_sg"
  }
}

# DB servers in private subnet
resource "aws_security_group" "wordpress_db_sg" {
  name = "wordpress_db_sg"
  description = "Securty Group for the RDS in the private subnet"
  vpc_id = "${aws_vpc.wordpress_vpc.id}"
  
  tags = {
    Name = "wordpress_db_sg"
  }
}

resource "aws_security_group_rule" "wordpress_db_sg_mysql" {
  type            = "ingress"
  from_port  = "${var.DB_PORT}"
  to_port    = "${var.DB_PORT}"
  protocol   = "tcp"
  source_security_group_id = "${aws_security_group.wordpress_webserver_sg.id}" # webserver security group

  security_group_id = "${aws_security_group.wordpress_db_sg.id}"
}

#EFS
resource "aws_security_group" "wordpress_efs_sg" {
  name        = "wordpress_efs_sg"
  description = "Allows NFS traffic from instances within the private subnet."
  vpc_id      = "${aws_vpc.wordpress_vpc.id}"

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"] # cidr blocks for private subnet
  }

  egress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
	cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"] # cidr blocks for private subnet
  }

  tags {
    Name = "wordpress_efs_sg"
  }
}