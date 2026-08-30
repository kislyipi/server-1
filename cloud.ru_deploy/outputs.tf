output "vm_id" {
  description = "ID виртуальной машины"
  value       = cloudru_evolution_compute_vm.vm.id
}

output "external_ip" {
  description = "Публичный IP адрес"
  value       = cloudru_evolution_compute_interface.vm_interface.external_ip.ip_address
}
