output "elastic_ip" {
  description = "Elastic IP k3s-server (target record A Hostinger)"
  value       = local.eip_public_ip
}

output "ssh_server" {
  value = "ssh -i gitops-lab-key.pem ubuntu@${local.eip_public_ip}"
}

output "ssh_agent_1" {
  value = "ssh -i gitops-lab-key.pem ubuntu@${aws_instance.agent["k3s-agent-1"].public_ip}"
}

output "ssh_agent_2" {
  value = "ssh -i gitops-lab-key.pem ubuntu@${aws_instance.agent["k3s-agent-2"].public_ip}"
}

output "api_endpoint" {
  description = "Alamat API Kubernetes (setelah record A dibuat)"
  value       = "https://api.${var.base_domain}:6443"
}

output "instance_ids" {
  description = "ID instance (untuk uji stop dan start)"
  value = {
    k3s-server  = aws_instance.server.id
    k3s-agent-1 = aws_instance.agent["k3s-agent-1"].id
    k3s-agent-2 = aws_instance.agent["k3s-agent-2"].id
  }
}

output "dns_instruction" {
  description = "Record DNS yang harus dibuat manual di Hostinger"
  value       = "Tipe A | Nama *.${split(".", var.base_domain)[0]} | Nilai ${local.eip_public_ip} | TTL 300"
}

output "hostnames" {
  value = [
    "argocd.${var.base_domain}",
    "nginx.${var.base_domain}",
    "httpd.${var.base_domain}",
    "keycloak.${var.base_domain}",
    "api.${var.base_domain}",
  ]
}

output "reminder" {
  value = "Isi email ClusterIssuer dengan ${var.letsencrypt_email} dan ganti seluruh placeholder kanjeeng.online pada repositori sebelum push."
}
