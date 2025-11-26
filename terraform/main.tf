terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.95.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Локальные значения для удобства
locals {
  bucket_name = "terraform-state-bucket-${var.yc_folder_id}"
}

# Создание сервисного аккаунта и ключей ДО backend
resource "yandex_iam_service_account" "terraform" {
  name        = "terraform-sa"
  description = "Service account for Terraform state management"
  folder_id   = var.yc_folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

resource "yandex_iam_service_account_static_access_key" "terraform_keys" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Static access key for Terraform state"
}

resource "yandex_storage_bucket" "terraform_state" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.terraform_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_keys.secret_key

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
}

# Настройка backend с использованием созданных ключей
resource "null_resource" "configure_backend" {
  depends_on = [yandex_storage_bucket.terraform_state]

  triggers = {
    access_key = yandex_iam_service_account_static_access_key.terraform_keys.access_key
    secret_key = yandex_iam_service_account_static_access_key.terraform_keys.secret_key
    bucket     = local.bucket_name
  }

  provisioner "local-exec" {
    command = <<EOT
      cat > backend.tf <<EOF
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "${local.bucket_name}"
    region     = "ru-central1"
    key        = "production/terraform.tfstate"
    access_key = "${yandex_iam_service_account_static_access_key.terraform_keys.access_key}"
    secret_key = "${yandex_iam_service_account_static_access_key.terraform_keys.secret_key}"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
EOF
    EOT
  }
}

# Инициализация Terraform с новым backend
resource "null_resource" "terraform_init" {
  depends_on = [null_resource.configure_backend]

  provisioner "local-exec" {
    command = "terraform init -force-copy"
  }
}

resource "yandex_compute_instance" "vm" {
  depends_on = [null_resource.terraform_init]

  name        = "production-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("./ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "network" {
  name = "terraform-network-production-vm"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "terraform-subnet-production-vm"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}