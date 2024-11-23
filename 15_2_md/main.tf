terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.133.0"
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

resource "yandex_storage_bucket" "my_bucket" {
  bucket     = "denis_2024-04-10"
}

resource "yandex_storage_object" "my_image" {
  bucket    = yandex_storage_bucket.my_bucket.name
  source    = "/home/bezumel/clopro/clopro-homeworks/15-2-md/800px-BMWM3E36-001.jpg" # Укажите путь к изображению на Вашем локальном компьютере
  key      = "800px-BMWM3E36-001.jpg"
}

resource "yandex_compute_instance_template" "lamp-template" {
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

  service_account_id = "aje7pg51sslo9ue74dm4"  # Укажите ID вашего сервисного аккаунта

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
