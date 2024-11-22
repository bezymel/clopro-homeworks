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
  route_table_id = "enpbfu3cd9smcmo3n55a"  // Замените на свой идентификатор таблицы маршрутов, если это необходимо
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = "enpbfu3cd9smcmo3n55a"  // Замените на свой идентификатор таблицы маршрутов, если это необходимо
}

// Создание внешнего IP для публичной ВМ
resource "yandex_compute_instance" "public_vm" {
  name = "public-vm"

  resources {
    cores = 4
    memory = 4
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat      = false
  }

  boot_disk {
    initialize_params {
      image_id = "fd8g2f1p8c2bpk14b4v0"  // Укажите нужный вам образ
    }
  }
}

// Пример NAT-инстанса для приватной ВМ
resource "yandex_compute_instance" "nat_instance" {
  name = "nat-instance"

  resources {
    cores = 2
    memory = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
  }

  boot_disk {
    initialize_params {
      image_id = "fd8g2f1p8c2bpk14b4v0"  // Укажите нужный вам образ
    }
  }
}

// Создание приватной ВМ
resource "yandex_compute_instance" "private_vm" {
  name = "private-vm"

  resources {
    cores  = 4
    memory = 4
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = true // Использование NAT для доступа к интернету
  }

  boot_disk {
    initialize_params {
      image_id = "fd8g2f1p8c2bpk14b4v0"  // Укажите нужный вам образ
    }
  }
}
