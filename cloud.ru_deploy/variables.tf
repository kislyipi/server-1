variable "project_id" {
  type        = string
  description = "Идентификатор проекта"
  default     = "40007d62-023b-4462-9ef0-d4d8d949dc3c"
}

variable "auth_key_id" {
  type        = string
  description = "Key ID сервисного аккаунта"
  sensitive   = true
  default     = ""
}

variable "auth_secret" {
  type        = string
  description = "Key Secret сервисного аккаунта"
  sensitive   = true
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Идентификатор подсети"
  default     = "aa951671-37bc-4f56-b5d0-909f482c0f56"
}

variable "zone" {
  type        = string
  description = "Зона доступности"
  default     = "ru.AZ-2"
}

variable "vm_name" {
  type        = string
  description = "Название ВМ"
  default     = "vm-47727e-tf"
}

variable "flavor" {
  type        = string
  description = "Флейвор ВМ"
  default     = "gen-2-8"
}

variable "disk_size" {
  type        = number
  description = "Размер диска в ГБ"
  default     = 20
}

variable "disk_type" {
  type        = string
  description = "Тип диска"
  default     = "SSD"
}

variable "image_name" {
  type        = string
  description = "Образ ОС"
  default     = "Ubuntu-24.04"
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH ключ"
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1oyiMmUL9Py4OG03mlxtjr70iP2T137xs7nCut3c2b main-pc"
}

variable "username" {
  type        = string
  description = "Имя пользователя в ВМ"
  default     = "kaloed"
}

variable "user_password_hash" {
  type        = string
  description = "SHA-512 хеш пароля. Генерация: python3 -c 'from passlib.hash import sha512_crypt; print(sha512_crypt.hash(\"пароль\"))'"
  sensitive   = true
  default     = ""
}

variable "ssh_private_key_path" {
  type        = string
  description = "Путь к приватному SSH ключу для Ansible (например ~/.ssh/id_ed25519)"
  default     = "~/.ssh/id_ed25519"
}
