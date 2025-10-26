terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = ${TF_VAR_toke}
  cloud_id  = ${TF_VAR_cloud_id}
  folder_id = ${TF_VAR_folder_id}
  zone      = ${TF_VAR_zone}
}

data "yandex_compute_image" "my-ubuntu-2004-1" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_instance" "my-vm-1" {
  name        = "test-vm-1"
  platform_id = "standard-v2"
  zone        = ${TF_VAR_zone}

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.my-ubuntu-2004-1.id}"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.my-sn-1.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    
  }
}

resource "yandex_vpc_network" "my-nw-1" {
  name = "my-nw-1"
}

resource "yandex_vpc_subnet" "my-sn-1" {
  zone           = ${TF_VAR_zone}
  network_id     = yandex_vpc_network.my-nw-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}



resource "yandex_lb_target_group" "my-target-group" {
  name      = "my-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = "${yandex_vpc_subnet.my-sn-1.id}"
    address   = "${yandex_compute_instance.my-vm-1.network_interface.0.ip_address}"
  }
}


resource "yandex_lb_network_load_balancer" "foo" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.my-target-group.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/"
      }
    }
  }
}




output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.my-vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.my-vm-1.network_interface.0.nat_ip_address
}
