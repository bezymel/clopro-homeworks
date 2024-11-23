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

resource "yandex_storage_bucket" "my_bucket" {
  bucket = "denis-10-04-1997" # Замените на ваше имя и дату. Пример: "ivanov-2024-04-01"
  storage_class = "standard"
  location = "ru-central1"
}

// Загрузка файла в бакет
resource "yandex_storage_object" "my_image" {
  bucket = yandex_storage_bucket.my_bucket.bucket
  name   = "my-image.png" // Замените на имя вашего файла
  source = "~/my-image.png" // Укажите путь к вашему изображению на локальной машине
}

// Группа ВМ с заданием для LAMP
resource "yandex_compute_instance_group" "lamp_group" {
  name        = "lamp-instance-group"
  zone        = "ru-central1-a"
  instances   = 3 // Количество инстансов
  platform_id = "standard-v1"

  template {
    resources {
      cores   = 2
      memory  = 2
    }

    network_interface {
      subnet_id = yandex_vpc_subnet.public_subnet.id
    }

    boot_disk {
      initialize_params {
        image_id = "fd81id4ciatai2csff2u" // Укажите ID образа LAMP
      }
    }

    metadata = {
      ssh-keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo8IE6EQzy6ilrIgbAn+85ccWqC5a7Ol6BgLr9KaHwB8gksrTq0Ur9UMAULaHuK4ZQHeRL5BQRsAjHXMV2tHP+/KGTSBg3D+bAF0XC4y7TUsa9J4/BW2PeV0HQnfK/VXTFEOnnu3pIZl5E4Z5MbzDM3A3aBj57badbetWAZLY/Kwq1IE9GWkkXEhUX8j6ymp6vlcd+7sAo5OEVv+HP8IBdO6ilwwbNreTH8UOyscBq2nm29d5jcRlvqxvripaQdvtFli8V6xRxS1B/7TQvoxL5u3GOigOMSC27km2g4fqIKlZ/LKX0yDGY3G/FHmJSYCt0Zt/WjmoC2yxUSYgrG7wP your_email@example.com"
    }
  }

  // Добавление healthcheck
  healthcheck {
    path      = "/"
    port      = 80
    protocol  = "HTTP"
    interval  = 30
    timeout   = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }
}

