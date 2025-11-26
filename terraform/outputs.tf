output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = yandex_compute_instance.vm.network_interface.0.nat_ip_address
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = yandex_compute_instance.vm.network_interface.0.ip_address
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = "ssh ubuntu@${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}

output "state_bucket_info" {
  description = "Information about the state bucket"
  value       = "State stored in: terraform-state-bucket-${var.yc_folder_id}"
}

output "vm_details" {
  description = "VM details"
  value = {
    name        = "production-vm"
    zone        = "ru-central1-a"
    cpu         = "2 cores"
    memory      = "2 GB"
    disk        = "20 GB"
    os          = "Ubuntu 22.04"
    external_ip = yandex_compute_instance.vm.network_interface.0.nat_ip_address
  }
}