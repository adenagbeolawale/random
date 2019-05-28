# RDS - Multi-AZ MySQL for HA
resource "aws_db_instance" "wordpress_db" {
    identifier = "${var.DB_NAME}"
    engine = "${var.DB_ENGINE}"
    engine_version = "${var.DB_ENGINE_VERSION}"
    allocated_storage = "${var.DB_STORAGE}"
    instance_class = "${var.DB_INSTANCE_TYPE}"
	storage_type = "gp2"
    vpc_security_group_ids = ["${aws_security_group.wordpress_db_sg.id}"]
    name = "${var.DB_NAME}"
    username = "${var.DB_ADMIN}"
    password = "${var.DB_PASSWORD}"
    parameter_group_name = "default.mysql5.7"
    db_subnet_group_name  = "${aws_db_subnet_group.aws_db_subnet_group.name}"
    backup_retention_period = 30
	multi_az = true
    skip_final_snapshot = true
    tags {
        Name = "wordpressdb"
    }
}

resource "aws_db_subnet_group" "aws_db_subnet_group" {
    name = "wordpress-db-subnet"
    description = "RDS subnet group"
    subnet_ids = ["${aws_subnet.wordpress_private_1.id}","${aws_subnet.wordpress_private_2.id}"]
}
