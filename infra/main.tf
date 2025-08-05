terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_network" "app_net" {
  name = "app_net"
}

resource "docker_image" "frontend_img" {
  name = "custom-frontend"
  build {
    context    = "${path.module}/../frontend"
  }
}

resource "docker_image" "backend_img" {
  name = "custom-backend"
  build {
    context    = "${path.module}/../backend"
  }
}

resource "docker_image" "nginx_img" {
  name = "custom-nginx"
  build {
    context = "${path.module}/../nginx"
  }
}

resource "docker_container" "frontend" {
  name  = "frontend"
  image = docker_image.frontend_img.image_id

  networks_advanced {
    name = docker_network.app_net.name
  }

  restart = "always"
}

resource "docker_container" "backend" {
  name  = "backend"
  image = docker_image.backend_img.image_id

  env = [
    "PORT=3000",
    "DB_HOST=${var.db_host}",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASS=${var.db_pass}",
    "DB_PORT=5432",
  ]

  networks_advanced {
    name = docker_network.app_net.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  restart = "always"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = docker_image.nginx_img.image_id

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app_net.name
  }

  depends_on = [
    docker_container.frontend,
    docker_container.backend
  ]

  restart = "always"
}

resource "docker_container" "db" {
  name  = "db"
  image = "postgres:15.8"

  env = [
    "POSTGRES_HOST=${var.db_host}",
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_pass}",
  ]

  networks_advanced {
    name = docker_network.app_net.name
  }

  volumes {
  container_path = "/docker-entrypoint-initdb.d/script.sql"
  host_path      = abspath("${path.module}/../sql/script.sql")
}

  restart = "always"
}
