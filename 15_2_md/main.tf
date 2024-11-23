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

// Создание NAT инстанса
resource "yandex_compute_instance" "nat_instance" {
  name            = "nat-instance"
  zone            = "ru-central1-a"
  platform_id     = "standard-v1"
  
  resources {
    cores = 2
    memory = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat      = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd81id4ciatai2csff2u" // Укажите необходимый ID образа
    }
  }

  metadata = {
    ssh-keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo8IE6EQzy6ilrIgbAn+85ccWqC5a7Ol6BgLr9KaHwB8gksrTq0Ur9UMAULaHuK4ZQHeRL5BQRsAjHXMV2tHP+/KGTSBg3D+bAF0XC4y7TUsa9J4/BW2PeV0HQnfK/VXTFEOnnu3pIZl5E4Z5MbzDM3A3aBj57badbetWAZLY/Kwq1IE9GWkkXEhUX8j6ymp6vlcd+7sAo5OEVv+HP8IBdO6ilwwbNreTH8UOyscBq2nm29d5jcRlvqxvripaQdvtFli8V6xRxS1B/7TQvoxL5u3GOigOMSC27km2g4fqIKlZ/LKX0yDGY3G/FHmJSYCt0Zt/WjmoC2yxUSYgrG7wP your_email@example.com"
  }
}

// Приватная виртуальная машина
resource "yandex_compute_instance" "private_instance" {
  name            = "private-instance"
  zone            = "ru-central1-a"
  platform_id     = "standard-v1"
  
  resources {
    cores = 2
    memory = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
  }

  boot_disk {
    initialize_params {
      image_id = "fd81id4ciatai2csff2u" // Укажите необходимый ID образа
    }
  }

  metadata = {
    ssh-keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo8IE6EQzy6ilrIgbAn+85ccWqC5a7Ol6BgLr9KaHwB8gksrTq0Ur9UMAULaHuK4ZQHeRL5BQRsAjHXMV2tHP+/KGTSBg3D+bAF0XC4y7TUsa9J4/BW2PeV0HQnfK/VXTFEOnnu3pIZl5E4Z5MbzDM3A3aBj57badbetWAZLY/Kwq1IE9GWkkXEhUX8j6ymp6vlcd+7sAo5OEVv+HP8IBdO6ilwwbNreTH8UOyscBq2nm29d5jcRlvqxvripaQdvtFli8V6xRxS1B/7TQvoxL5u3GOigOMSC27km2g4fqIKlZ/LKX0yDGY3G/FHmJSYCt0Zt/WjmoC2yxUSYgrG7wP your_email@example.com"
  }
}

// Создание бакета
resource "yandex_storage_bucket" "my_bucket" {
  bucket = "denis-10-04-1997" // Измените на ваше уникальное имя
}

// Загрузка файла в бакет
resource "yandex_storage_object" "my_image" {
  bucket = yandex_storage_bucket.my_bucket.bucket
  source = "/absolute/path/to/your/my-image.png" // Путь к изображению
  key    = "my-image.png"
}

// Создание группы ВМ
resource "yandex_compute_instance_group" "lamp_group" {
  name = "lamp-group"
  zone = "ru-central1-a"
  
  instance_template {
    boot_disk {
      image_id = "fd827b91d99psvq5fjit" // Образ LAMP
    }

    resources {
      cores  = 2
      memory = 2
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.private_subnet.id]
      nat       = true
    }

    metadata = {
      ssh-keys = "ssh-rsa AAAAB3... your_email@example.com"
      user_data = <<-EOF
        #!/bin/bash
        echo "<html><body><h1>Image from Bucket</h1>" > /var/www/html/index.html
        echo "<img src='${yandex_storage_bucket.my_bucket.bucket}/${yandex_storage_object.my_image.key}' />" >> /var/www/html/index.html
        echo "</body></html>" >> /var/www/html/index.html
      EOF
    }
  }

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 3
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    strategy             = "proactive"
    max_unavailable      = 1
  }

  scale_policy {
    fixed_scale {
      size = 3 // Количество ВМ
    }
  }
}

// Создание сетевого балансировщика
resource "yandex_lb_network_load_balancer" "network_lb" {
  name = "my-lb"
  
  region = "ru-central1"

  listener {
    name     = "listener"
    port     = 80
    protocol = "tcp"
  }

  backend {
    group_id = yandex_compute_instance_group.lamp_group.id
  }

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 3
  }

}
