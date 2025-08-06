terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

# Rede Docker para todos os containers
resource "docker_network" "cubos_network" {
  name = "cubos_network"
}

# Volume do PostgreSQL
resource "docker_volume" "pgdata" {
  name = "pgdata"
}

# Imagem do PostgreSQL
resource "docker_image" "db_image_cubos" {
  name         = "postgres:15.8"
  keep_locally = true
}

# Container do PostgreSQL
resource "docker_container" "db_container_cubos" {
  name  = "db_cubos"
  image = docker_image.db_image_cubos.name

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_pass}"
  ]

  networks_advanced {
    name = docker_network.cubos_network.name
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.pgdata.name
  }

  volumes {
    container_path = "/docker-entrypoint-initdb.d/script.sql"
    host_path      = abspath("${path.module}/../sql/script.sql")
  }

  restart = "always"
}

# Imagem do Backend
resource "docker_image" "backend_image_cubos" {
  name = "backend:1.0.0"

  build {
    context    = "${path.module}/../backend"
    dockerfile = "Dockerfile"
  }
}

# Container do Backend
resource "docker_container" "backend_container_cubos" {
  name  = "backend_cubos"
  image = docker_image.backend_image_cubos.name

  env = [
    "DB_HOST=db_cubos",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASS=${var.db_pass}",
    "DB_PORT=5432",
    "PORT=3000"
  ]

  networks_advanced {
    name = docker_network.cubos_network.name
  }

  restart = "always"

  depends_on = [
    docker_container.db_container_cubos
  ]
}

# Imagem do Frontend com NGINX
resource "docker_image" "frontend_image" {
  name = "frontend:1.0.0"

  build {
    context    = "${path.module}/../frontend"
    dockerfile = "Dockerfile"
  }
}

# Container do Frontend
resource "docker_container" "frontend_container" {
  name  = "frontend_container"
  image = docker_image.frontend_image.name

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.cubos_network.name
  }

  restart = "always"

  depends_on = [
    docker_container.backend_container_cubos
  ]
}

# Executa script para gerar SQL dinamicamente
resource "null_resource" "generate_sql" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "./../sql/generate_sql.sh"
  }
}
