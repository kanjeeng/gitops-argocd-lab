provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "gitops-argocd-lab"
      Session = "Sesi27-GitOps"
    }
  }
}
