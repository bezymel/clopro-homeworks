terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.69"
    }
  }

  required_version = ">= 1.0"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "my_vpc" {
  name = "my-vpc"
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_storage_bucket" "my_bucket" {
  name     = "denis_2024-04-10"
  public_access   = "public-read"
}

resource "yandex_storage_object" "my_image" {
  bucket    = yandex_storage_bucket.my_bucket.name
  source    = "/home/bezumel/clopro/clopro-homeworks/15-2-md/800px-BMWM3E36-001.jpg" # Укажите путь к изображению на Вашем локальном компьютере
  name      = "800px-BMWM3E36-001.jpg"
}

resource "yandex_compute_instance_template" "template" {
  name        = "lamp-template"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" // ID образа для LAMP
    }
  }

  metadata = {
    user_data = <<-EOF
                #!/bin/bash
                echo "<html>" > /var/www/html/index.html
                echo "<h1>Привет, мир!</h1>" >> /var/www/html/index.html
                echo "<img src='https://storage.yandexcloud.net/denis_2024-04-10/800px-BMWM3E36-001.jpg'/>" >> /var/www/html/index.html
                echo "</html>" >> /var/www/html/index.html
                systemctl restart nginx
                EOF
  }
}

resource "yandex_compute_instance_group" "instance_group" {
  name        = "lamp-instance-group"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  instance_template_id = yandex_compute_instance_template.template.id
  scale               = 3

  health_check {
    http_options {
      port = 80
      path = "/"
    }
    interval = 5
    timeout  = 2
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    strategy             = "proactive"
    max_unavailable      = 10
    max_expansion        = 10
  }

  scale_policy {
    fixed_scale {
      size = 3 // Количество инстансов
    }
  }
}

resource "yandex_network_load_balancer" "nlb" {
  name = "my-nlb"

  listener {
    port   = 80
    ip_version = "ipv4"
  }

  backend {
    group_id = yandex_compute_instance_group.instance_group.id
    port     = 80
  }
}
