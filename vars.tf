# Variables
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}

variable "AWS_REGION" {
  default = "eu-west-2"
}

#AUTOSCALING AND LAUNCH CONFIGURATION
variable "AMIS" {
  type = "map"
  default = {
    eu-west-2 = "ami-05663d374a152d239" #Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type - ami-05663d374a152d239
  }
}

variable "EC2_INSTACE_TYPE" {
	default = "t2.micro"
}

variable "NO_OF_SUBNETS" {
	default = "2"
}

variable "AUTOSCALING_MIN_SIZE" {
	default = "2"
}

variable "AUTOSCALING_MAX_SIZE" {
	default = "5"
}

# DATABASE
variable "DB_ADMIN" {}
variable "DB_PASSWORD" {}

variable "DB_PORT" {
	default = "3306"
}

variable "DB_NAME" {
	default = "wordpressdb"
}

variable "DB_ENGINE" {
	default = "mysql"
}

variable "DB_ENGINE_VERSION" {
	default = "5.7"
}

variable "DB_INSTANCE_TYPE" {
	default = "db.m4.large" #this supports multi_az
}

variable "DB_STORAGE" {
	default = "100" #for better iops performance
}

#IP allowed to connect to Bastion
variable "SSH_IP_RANGE" {
	#put my IP here
	default = "94.10.243.167/32"
}

variable "PATH_TO_PUBLIC_KEY" {
	default = ""
}

#VPC
variable "PUBLIC_CIDR" {
	type = "list"
	default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "PRIVATE_CIDR" {
	type = "list"
	default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "AVAILABILITY_ZONES" {
	type = "list"
	default = ["eu-west-1a", "eu-west-1b"]
}

#ELB
variable "ALB_NAME" {
	default = "wordpress_alb"
}

variable "ALB_TARGETGROUP_NAME" {
	default = "wordpress_alb_tg"
}

variable "LB_IDLE_TIMOUT" {
	default= "60"
}

variable "ALB_LISTERNER_PORT" {
	default = "80"
}

variable "ALB_LISTERNER_PROTOCOL" {
	default = "HTTP"
}

variable "ALB_PRIORITY" {
	default = "100"
}

variable "ALB_HEALTHCHEK_PATH" {
	default = "/healthcheck.html"
}

variable "TARGET_GROUP_PORT" {
	default = "80"
}

#CLOUDFRONT
variable "CLOUDFRONT_PRICE_CLASS" {
	default = "PriceClass_200"
}

variable "CLOUDFRONT_ALIASES" {
	type = "list"
	default = []
}