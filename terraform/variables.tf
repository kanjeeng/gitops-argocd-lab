variable "aws_region" {
  description = "Region AWS untuk lab"
  type        = string
  default     = "ap-southeast-1"
}

variable "admin_cidr" {
  description = "IP publik operator dalam format CIDR, contoh 182.5.242.249/32"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR VPC"
  type        = string
  default     = "10.4.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR public subnet"
  type        = string
  default     = "10.4.1.0/24"
}

variable "server_instance_type" {
  description = "Tipe instance control-plane"
  type        = string
  default     = "t3.medium"
}

variable "agent_instance_type" {
  description = "Tipe instance worker. Naikkan ke t3.large jika Keycloak dan monitoring dijalankan bersamaan"
  type        = string
  default     = "t3.medium"
}

variable "use_spot" {
  description = "true = EC2 Spot persistent (perilaku stop saat interupsi). false = On-Demand"
  type        = bool
  default     = true
}

variable "k3s_version" {
  description = "Versi k3s yang dipin. Kosongkan untuk memakai channel stable terbaru"
  type        = string
  default     = "v1.31.4+k3s1"
}

variable "base_domain" {
  description = "Subdomain lab pada domain Hostinger, contoh gitops.kanjeeng.online"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email akun ACME Let's Encrypt (dipakai pada manifest ClusterIssuer, ditampilkan sebagai pengingat di output)"
  type        = string
}

variable "existing_eip_allocation_id" {
  description = "Opsional: allocation ID Elastic IP yang sudah ada (eipalloc-xxxx) agar alamat tidak berubah antar apply. Kosong = Terraform membuat Elastic IP baru"
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "true = pasang IAM instance profile AmazonSSMManagedInstanceCore untuk akses SSM Session Manager"
  type        = bool
  default     = false
}
