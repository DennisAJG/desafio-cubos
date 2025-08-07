variable "db_name" {
  default = "db_cubos"
}

variable "db_user" {
  default = "admin"
}

variable "db_pass" {
  sensitive = true
  default   = "secure_p4$$w0rd"
}

variable "db_port" {
  default = 5432
}

variable "db_host" {
  default = "db_cubos"
}

variable "backend_port" {
  default = 3000
}
