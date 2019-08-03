provider "aws" {
  region = "ap-southeast-1"
  version = "~> 1.58"
}

#######################
####VPC
#######################

#VPC definition with 6 subnet ranges
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "1.67.0"

  name = "django-ha-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

#######################
####EC2-INSTANCE
#######################

#ec2 instance launch for apps
module "app" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 1.0"

  name                   = "my-cluster"
  instance_count         = 2

  ami                    = "ami-009683ff29bf33c5f"
  instance_type          = "t2.micro"
  key_name               = "sreekanth-key"
  monitoring             = false
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}", "${aws_security_group.allow_ssh_slave.id}"]
  subnet_id              = "${element(module.vpc.private_subnets, 0)}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
#ec2 instance launch for jump
module "jump" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 1.0"

  name                   = "jump"
  instance_count         = 1

  ami                    = "ami-009683ff29bf33c5f"
  instance_type          = "t2.micro"
  key_name               = "sreekanth-key"
  monitoring             = false
  associate_public_ip_address	= true
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id              = "${element(module.vpc.public_subnets, 0)}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#######################
####SECURITY GROUPS
#######################

#security-grp for apps connection
resource "aws_security_group" "allow_tls" {
  name        = "django-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"
      ingress {
    # TLS (change to whatever ports you need)
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.101.0/24"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_elb_tls" {
  name        = "django-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"
      ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#security-grp for apps slave connection via ssh
resource "aws_security_group" "allow_ssh_slave" {
  name        = "slave-ssh"
  description = "Allow SSH access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.101.0/24"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#security-grp for jump connection via ssh
resource "aws_security_group" "allow_ssh" {
  name        = "jump-ssh"
  description = "Allow SSH access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["182.75.87.26/32"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
#security-grp for RDS
resource "aws_security_group" "allow_rds" {
  name        = "rds_conn"
  description = "Allow access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = "${var.rds_port}"
    to_port     = "${var.rds_port}"
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.101.0/24", "10.0.1.0/24"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#######################
####ELB
#######################
module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 1.4.1"

  name = "elb-django"

  subnets         = "${module.vpc.public_subnets}"
  security_groups = ["${aws_security_group.allow_elb_tls.id}"]
  internal        = false

  listener = [
    {
      instance_port     = "8000"
      instance_protocol = "TCP"
      lb_port           = "80"
      lb_protocol       = "TCP"
    },
    {
      instance_port     = "8000"
      instance_protocol = "TCP"
      lb_port           = "8000"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [{
    target              = "TCP:8000"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }]
  #access_logs = {
  #  bucket = "my-access-logs-bucket"
  #}
  // ELB attachments
  number_of_instances = 1
  instances           = "${module.app.id}"

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

#######################
####RDS
#######################
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 1.28.0"

  identifier = "django-db"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  publicly_accessible = false
  #max_allocated_storage = 25
  #performance_insights_enabled = false

  name     = "${var.rds_name}"
  username = "${var.rds_user}"
  password = "${var.rds_password}"
  port     = "${var.rds_port}"

  iam_database_authentication_enabled = false

  vpc_security_group_ids = ["${aws_security_group.allow_rds.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  #monitoring_interval = "30"
  #monitoring_role_name = "MyRDSMonitoringRole"
  #create_monitoring_role = false

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = ["${element(module.vpc.private_subnets, 0)}", "${element(module.vpc.private_subnets, 1)}"]

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion
  #final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  deletion_protection = false

#  parameters = [
#    {
#      name = "character_set_client"
#      value = "utf8"
#    },
#    {
#      name = "character_set_server"
#      value = "utf8"
#    }
#  ]
#
#  options = [
#    {
#      option_name = "MARIADB_AUDIT_PLUGIN"
#
#      option_settings = [
#        {
#          name  = "SERVER_AUDIT_EVENTS"
#          value = "CONNECT"
#        },
#        {
#          name  = "SERVER_AUDIT_FILE_ROTATIONS"
#          value = "37"
#        },
#      ]
#    },
#  ]
}