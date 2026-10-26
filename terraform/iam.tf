# Opsional: akses SSM Session Manager tanpa membuka port 22.
resource "aws_iam_role" "ssm" {
  count = var.enable_ssm ? 1 : 0

  name = "gitops-lab-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_ssm ? 1 : 0

  name = "gitops-lab-ssm-profile"
  role = aws_iam_role.ssm[0].name
}
