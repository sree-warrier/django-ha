variable "rds_name" {
  description = "Name of RDS instance"
}

variable "rds_user" {
  description = "Name of RDS user"
}

variable "rds_password" {
  description = "RDS Password"
}

variable "rds_port" {
  description = "RDS port"
  default = 3306
}