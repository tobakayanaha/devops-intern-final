variable "image_tag" {
  type        = string
  description = "Tag of the ghcr.io/tobakayanaha/devops-intern-final image to deploy"
  default     = "latest"
}

job "nginx-app" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "2m"
    auto_revert       = true
  }

  group "nginx-app" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      delay          = "10s"
      delay_function = "exponential"
      max_delay      = "1h"
      unlimited      = true
    }

    task "nginx-app" {
      driver = "docker"

      config {
        image = "ghcr.io/tobakayanaha/devops-intern-final:${var.image_tag}"
        ports = ["http"]
        
      }
      shutdown_delay = "5s"


      resources {
        cpu    = 100 # MHz
        memory = 64  # MB
      }

      service {
        name     = "nginx-app"
        port     = "http"
        provider = "consul"

        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}