# Dua Security Group dibuat kosong, aturan dipasang sebagai resource terpisah
# agar referensi silang antar SG (server <-> agent) tidak membentuk siklus.

resource "aws_security_group" "server" {
  name        = "k3s-server-sg"
  description = "k3s control-plane dan ingress web"
  vpc_id      = aws_vpc.lab.id

  tags = { Name = "k3s-server-sg" }
}

resource "aws_security_group" "agent" {
  name        = "k3s-agent-sg"
  description = "k3s worker"
  vpc_id      = aws_vpc.lab.id

  tags = { Name = "k3s-agent-sg" }
}

locals {
  server_ingress_cidr = {
    api_admin = {
      from = 6443, to = 6443, protocol = "tcp", cidr = var.admin_cidr
      desc = "Kubernetes API dari admin"
    }
    ssh_admin = {
      from = 22, to = 22, protocol = "tcp", cidr = var.admin_cidr
      desc = "SSH admin"
    }
    http_public = {
      from = 80, to = 80, protocol = "tcp", cidr = "0.0.0.0/0"
      desc = "HTTP Traefik dan validasi ACME HTTP-01"
    }
    https_public = {
      from = 443, to = 443, protocol = "tcp", cidr = "0.0.0.0/0"
      desc = "HTTPS Traefik"
    }
    nodeport_admin = {
      from = 30000, to = 32767, protocol = "tcp", cidr = var.admin_cidr
      desc = "NodePort dari admin (pengujian)"
    }
  }

  server_ingress_from_agent = {
    api     = { from = 6443, to = 6443, protocol = "tcp", desc = "API untuk join dan kubelet agent" }
    vxlan   = { from = 8472, to = 8472, protocol = "udp", desc = "Flannel VXLAN dari agent" }
    kubelet = { from = 10250, to = 10250, protocol = "tcp", desc = "Kubelet dari agent" }
  }

  agent_ingress_cidr = {
    ssh_admin = {
      from = 22, to = 22, protocol = "tcp", cidr = var.admin_cidr
      desc = "SSH admin"
    }
    nodeport_admin = {
      from = 30000, to = 32767, protocol = "tcp", cidr = var.admin_cidr
      desc = "NodePort dari admin (pengujian)"
    }
  }

  agent_ingress_from_server = {
    vxlan   = { from = 8472, to = 8472, protocol = "udp", desc = "Flannel VXLAN dari server" }
    kubelet = { from = 10250, to = 10250, protocol = "tcp", desc = "Kubelet dari server" }
  }

  agent_ingress_from_agent = {
    vxlan   = { from = 8472, to = 8472, protocol = "udp", desc = "Flannel VXLAN antar agent" }
    kubelet = { from = 10250, to = 10250, protocol = "tcp", desc = "Kubelet antar agent" }
  }
}

resource "aws_vpc_security_group_ingress_rule" "server_cidr" {
  for_each = local.server_ingress_cidr

  security_group_id = aws_security_group.server.id
  description       = each.value.desc
  cidr_ipv4         = each.value.cidr
  ip_protocol       = each.value.protocol
  from_port         = each.value.from
  to_port           = each.value.to
}

resource "aws_vpc_security_group_ingress_rule" "server_from_agent" {
  for_each = local.server_ingress_from_agent

  security_group_id            = aws_security_group.server.id
  description                  = each.value.desc
  referenced_security_group_id = aws_security_group.agent.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
}

resource "aws_vpc_security_group_ingress_rule" "agent_cidr" {
  for_each = local.agent_ingress_cidr

  security_group_id = aws_security_group.agent.id
  description       = each.value.desc
  cidr_ipv4         = each.value.cidr
  ip_protocol       = each.value.protocol
  from_port         = each.value.from
  to_port           = each.value.to
}

resource "aws_vpc_security_group_ingress_rule" "agent_from_server" {
  for_each = local.agent_ingress_from_server

  security_group_id            = aws_security_group.agent.id
  description                  = each.value.desc
  referenced_security_group_id = aws_security_group.server.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
}

resource "aws_vpc_security_group_ingress_rule" "agent_from_agent" {
  for_each = local.agent_ingress_from_agent

  security_group_id            = aws_security_group.agent.id
  description                  = each.value.desc
  referenced_security_group_id = aws_security_group.agent.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
}

resource "aws_vpc_security_group_egress_rule" "server_all" {
  security_group_id = aws_security_group.server.id
  description       = "Seluruh egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "agent_all" {
  security_group_id = aws_security_group.agent.id
  description       = "Seluruh egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
