terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

# ---------------------
# Redes
# ---------------------
resource "docker_network" "frontend_network" {
  name = "frontend_network"
}

resource "docker_network" "backend_network" {
  name = "backend_network"
}

# ---------------------
# Volume do PostgreSQL
# ---------------------
resource "docker_volume" "pgdata" {
  name = "pgdata"
}

# ---------------------
# PostgreSQL
# ---------------------
resource "docker_image" "db_image_cubos" {
  name         = "postgres:15.8"
  keep_locally = true
}

resource "docker_container" "db_container_cubos" {
  name  = "db_cubos"
  image = docker_image.db_image_cubos.name

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_pass}"
  ]

  networks_advanced {
    name = docker_network.backend_network.name
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

# ---------------------
# Backend
# ---------------------
resource "docker_image" "backend_image_cubos" {
  name = "backend:1.0.0"

  build {
    context    = "${path.module}/../backend"
    dockerfile = "Dockerfile"
  }
}

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
    name = docker_network.backend_network.name
    aliases = ["backend_cubos"]
  }

  restart = "always"

  depends_on = [docker_container.db_container_cubos]
}

# ---------------------
# Frontend
# ---------------------
resource "docker_image" "frontend_image_cubos" {
  name = "frontend:1.0.0"

  build {
    context    = "${path.module}/../frontend"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "frontend_container_cubos" {
  name  = "frontend_cubos"
  image = docker_image.frontend_image_cubos.name

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.frontend_network.name
  }

  networks_advanced {
    name = docker_network.backend_network.name
  }

  restart = "always"

  depends_on = [docker_container.backend_container_cubos]
}

# ---------------------
# Prometheus
# ---------------------
resource "docker_image" "prometheus_image" {
  name = "prometheus_custom:latest"

  build {
    context    = "${path.module}/../monitoring/prometheus"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus_image.name

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name = docker_network.backend_network.name
    aliases = [ "prometheus" ]
  }

  restart = "always"

  depends_on = [docker_container.backend_container_cubos]
}

# ---------------------
# Grafana
# ---------------------
resource "docker_image" "grafana_image" {
  name = "grafana_custom:latest"

  build {
    context    = "${path.module}/../monitoring/grafana"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana_image.name

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.backend_network.name
  }

  restart = "always"
}

# ---------------------
# Script de geração do SQL inicial
# ---------------------
resource "null_resource" "generate_sql" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "./../sql/generate_sql.sh"
  }
}


# ---------------------
# Container do cAdvisor
# ---------------------
resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = "gcr.io/cadvisor/cadvisor:v0.47.2"

  ports {
    internal = 8080
    external = 8081
  }

  networks_advanced {
    name = docker_network.backend_network.name
  }
  
  restart = "always"

  volumes {
    container_path = "/var/run"
    host_path      = "/var/run"
    read_only      = false
  }

  volumes {
    container_path = "/sys"
    host_path      = "/sys"
    read_only      = true
  }

  privileged = true

  volumes {
    container_path = "/var/lib/docker"
    host_path      = "/var/lib/docker"
    read_only      = true
  }
}
