data "cloudru_evolution_compute_image_collection" "ubuntu" {
  project_id = var.project_id
  page_size  = 100
}

locals {
  cloud_config_with_password = <<-YAML
#cloud-config
groups:
  - admingroup
  - root
  - sys
  - cloud-users

hostname: ${var.vm_name}

users:
  - name: ${var.username}
    groups: users
    lock_passwd: false
    primary_group: ${var.username}
    passwd: ${var.user_password_hash}
    ssh_authorized_keys:
      - ${var.ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: true
apt:
  primary:
    - arches: [default]
      uri: http://mirror.yandex.ru/ubuntu/
YAML

  cloud_config_without_password = <<-YAML
#cloud-config
groups:
  - admingroup
  - root
  - sys
  - cloud-users

hostname: ${var.vm_name}

users:
  - name: ${var.username}
    groups: users
    lock_passwd: false
    primary_group: ${var.username}
    ssh_authorized_keys:
      - ${var.ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: true
apt:
  primary:
    - arches: [default]
      uri: http://mirror.yandex.ru/ubuntu/
YAML

  cloud_config = var.user_password_hash != "" ? local.cloud_config_with_password : local.cloud_config_without_password
}


resource "cloudru_evolution_compute_security_group" "vm_sg" {
  project_id = var.project_id
  name       = "${var.vm_name}-sg"
  zone_identifier = { name = var.zone }
  description = "Группа безопасности для ${var.vm_name}"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_ssh" {
  security_group_id = cloudru_evolution_compute_security_group.vm_sg.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "22:22"
  description       = "SSH доступ"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_tcp" {
  security_group_id = cloudru_evolution_compute_security_group.vm_sg.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "1:65535"
  description       = "Разрешить весь исходящий TCP"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_udp" {
  security_group_id = cloudru_evolution_compute_security_group.vm_sg.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_UDP"
  port_range        = "1:65535"
  description       = "Разрешить весь исходящий UDP"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_disk" "vm_disk" {
  project_id = var.project_id
  name       = "${var.vm_name}-disk"
  size       = var.disk_size
  zone_identifier = { name = var.zone }
  disk_type_identifier = { name = var.disk_type }
  description = "Загрузочный диск для ${var.vm_name}"
  bootable    = true
  image_id    = [for img in data.cloudru_evolution_compute_image_collection.ubuntu.images : img.id if img.name == var.image_name][0]
  encrypted   = false
  readonly    = false
  shared      = false
}

resource "cloudru_evolution_compute_interface" "vm_interface" {
  project_id = var.project_id
  name       = "${var.vm_name}-interface"
  zone_identifier = { name = var.zone }
  description = "Сетевой интерфейс для ${var.vm_name}"
  subnet_id = var.subnet_id

  interface_security_enabled = true
  security_groups_identifiers = {
    value = [{ id = cloudru_evolution_compute_security_group.vm_sg.id }]
  }

  external_ip_specs = { new_external_ip = true }
  type = "INTERFACE_TYPE_REGULAR"
}

resource "cloudru_evolution_compute_vm" "vm" {
  project_id = var.project_id
  name       = var.vm_name
  zone_identifier = { name = var.zone }
  flavor_identifier = { name = var.flavor }
  description = "ВМ, созданная через Terraform"

  disk_identifiers = [{ disk_id = cloudru_evolution_compute_disk.vm_disk.id }]
  network_interfaces = [{ interface_id = cloudru_evolution_compute_interface.vm_interface.id }]
  cloud_init_userdata = base64encode(local.cloud_config)

  provisioner "local-exec" {
    command = <<-EOT
      # Ждём пока SSH станет доступен
      echo "Waiting for SSH on ${cloudru_evolution_compute_interface.vm_interface.external_ip.ip_address}..."
      until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes -i ${var.ssh_private_key_path} ${var.username}@${cloudru_evolution_compute_interface.vm_interface.external_ip.ip_address} exit 2>/dev/null; do
        sleep 10
      done
      echo "SSH is ready."

      # Ждём пока cloud-init завершится (важно!)
      echo "Waiting for cloud-init to finish..."
      until ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.username}@${cloudru_evolution_compute_interface.vm_interface.external_ip.ip_address} "curl -sf http://169.254.169.254/hetzner/v1/metadata/public-ipv4 || echo done" 2>/dev/null | grep -q done; do
        sleep 5
      done
      sleep 10

      # Генерируем inventory
      echo "[vm]" > ${path.module}/deploy/inventory
      echo "${var.username}@${cloudru_evolution_compute_interface.vm_interface.external_ip.ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path} ansible_python_interpreter=/usr/bin/python3" >> ${path.module}/deploy/inventory

      # Запускаем Ansible (БЕЗ on_failure — ошибка прервёт apply)
      cd ${path.module}/deploy && \
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i inventory playbook.yml -v
    EOT
  }
}
