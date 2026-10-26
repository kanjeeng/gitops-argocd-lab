# Token klaster acak. Server dan agent memakai token yang sama
# sehingga proses join agent tidak membutuhkan langkah manual.
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}
