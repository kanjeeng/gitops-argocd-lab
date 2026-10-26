data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------- Elastic IP (baru atau yang sudah ada) ----------------
resource "aws_eip" "server" {
  count = var.existing_eip_allocation_id == "" ? 1 : 0

  domain = "vpc"
  tags   = { Name = "k3s-server-eip" }
}

data "aws_eip" "existing" {
  count = var.existing_eip_allocation_id != "" ? 1 : 0

  id = var.existing_eip_allocation_id
}

locals {
  server_private_ip = "10.4.1.10"

  agents = {
    "k3s-agent-1" = "10.4.1.21"
    "k3s-agent-2" = "10.4.1.22"
  }

  eip_public_ip     = one(concat(aws_eip.server[*].public_ip, data.aws_eip.existing[*].public_ip))
  eip_allocation_id = one(concat(aws_eip.server[*].id, data.aws_eip.existing[*].id))
  ssm_profile_name  = one(aws_iam_instance_profile.ssm[*].name)
}

# ---------------- k3s-server (control-plane) ----------------
resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.server_instance_type
  subnet_id              = aws_subnet.public.id
  private_ip             = local.server_private_ip
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.server.id]
  iam_instance_profile   = local.ssm_profile_name

  dynamic "instance_market_options" {
    for_each = var.use_spot ? [1] : []

    content {
      market_type = "spot"

      spot_options {
        spot_instance_type             = "persistent"
        instance_interruption_behavior = "stop"
      }
    }
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = templatefile("${path.module}/userdata/k3s-server.sh", {
    k3s_version = var.k3s_version
    k3s_token   = random_password.k3s_token.result
    eip         = local.eip_public_ip
    base_domain = var.base_domain
  })
  user_data_replace_on_change = true

  tags       = { Name = "k3s-server" }
  depends_on = [aws_internet_gateway.lab]
}

resource "aws_eip_association" "server" {
  instance_id   = aws_instance.server.id
  allocation_id = local.eip_allocation_id
}

# ---------------- k3s-agent-1 dan k3s-agent-2 (worker) ----------------
resource "aws_instance" "agent" {
  for_each = local.agents

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.agent_instance_type
  subnet_id              = aws_subnet.public.id
  private_ip             = each.value
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.agent.id]
  iam_instance_profile   = local.ssm_profile_name

  dynamic "instance_market_options" {
    for_each = var.use_spot ? [1] : []

    content {
      market_type = "spot"

      spot_options {
        spot_instance_type             = "persistent"
        instance_interruption_behavior = "stop"
      }
    }
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = templatefile("${path.module}/userdata/k3s-agent.sh", {
    k3s_version = var.k3s_version
    k3s_token   = random_password.k3s_token.result
    server_ip   = local.server_private_ip
    node_name   = each.key
    node_ip     = each.value
  })
  user_data_replace_on_change = true

  tags       = { Name = each.key }
  depends_on = [aws_instance.server]
}
