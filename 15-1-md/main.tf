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
