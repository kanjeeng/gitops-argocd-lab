# gitops-argocd-lab

Praktikum **GitOps (Sesi 27)** dengan **ArgoCD** di **AWS (ap-southeast-1)**.

Tugas inti: deploy `simple-nginx` dan `simple-httpd` ke Kubernetes, suplai `index.html` lewat ConfigMap, expose dengan Service/Ingress, lalu uji akses. Proyek ini memperluasnya menjadi platform GitOps bergaya production:

| Level | Cakupan |
|---|---|
| 1 (inti tugas) | Klaster k3s, ArgoCD, ConfigMap `index.html`, Deployment, Service dan Ingress, uji akses |
| 2 (production-style) | Traefik + cert-manager (HTTPS Let's Encrypt), app-of-apps, sync waves, AppProject, drift dan self-heal, rolling update, rollback |
| 3 (advanced) | SSO Keycloak, RBAC per grup, ApplicationSet multi-environment, validasi manifest di CI |

Langkah pengerjaan lengkap (command dan penjelasan) ada pada dokumen BAB II. README ini adalah ringkasan teknis repositori.

## Arsitektur

```
Operator (laptop) --SSH/6443/80/443--> Internet --> IGW --> VPC 10.4.0.0/16
                                                    Public subnet 10.4.1.0/24
   k3s-server  10.4.1.10 (+Elastic IP)  control-plane, ServiceLB 80/443, Traefik
   k3s-agent-1 10.4.1.21                worker: ArgoCD, cert-manager, apps
   k3s-agent-2 10.4.1.22                worker: Keycloak, apps
GitHub (gitops-argocd-lab) <--pull (HTTPS)-- ArgoCD  = single source of truth
```

Infrastruktur dibuat Terraform (VPC, Security Group, 3 EC2 Spot, Elastic IP, kunci SSH, instalasi k3s via User Data). ArgoCD dipasang manual (bootstrap), selanjutnya seluruh platform dan aplikasi dikelola dari Git.

## Struktur repositori

```
gitops-argocd-lab/
├── README.md
├── .gitignore
├── terraform/                      # IaC AWS dan instalasi k3s
│   ├── versions.tf  providers.tf  variables.tf  terraform.tfvars.example
│   ├── network.tf  security-groups.tf  keypair.tf  k3s-token.tf  iam.tf
│   ├── ec2.tf  outputs.tf
│   └── userdata/{k3s-server.sh,k3s-agent.sh}
├── bootstrap/                      # Nilai Helm ArgoCD (bootstrap dan SSO)
├── argocd/
│   ├── projects/                   # AppProject: platform, demo-project
│   ├── root-app.yaml               # App-of-apps Level 1-2
│   ├── root-app-level3.yaml        # App-of-apps Level 3
│   ├── applications/               # Application per komponen dan aplikasi
│   ├── level3/                     # Keycloak dan ApplicationSet
│   └── tests/forbidden-app.yaml    # Uji penolakan AppProject (G-17)
├── platform/
│   ├── cert-manager/{values.yaml,issuers/}
│   ├── traefik/values.yaml
│   ├── argocd/                     # Ingress dan middleware allowlist dashboard
│   └── keycloak/                   # Keycloak dan PostgreSQL (Level 3)
├── apps/
│   ├── simple-nginx/{base,overlays/{dev,dev-nodeport,prod}}
│   └── simple-httpd/{base,overlays/{dev,dev-nodeport,prod}}
├── .github/workflows/validate.yaml # CI validasi manifest (Level 3)
└── docs/                           # Screenshot bukti
```

## Placeholder yang wajib diganti

Ganti sebelum `git push`. Gunakan fitur *Replace in Files* pada editor (misalnya VS Code), lalu verifikasi dengan `git grep --untracked -n -E "kanjeeng.online|kanjeeng|182.6.88.234"` (hasil harus kosong).

| Placeholder | Ganti dengan | Muncul di |
|---|---|---|
| `gitops.kanjeeng.online` | Subdomain lab Anda (misalnya `gitops.domainanda.com`) | `terraform.tfvars`, `bootstrap/*`, `platform/argocd`, `platform/keycloak`, `apps/*/overlays/*` |
| `dimasleny210@gmail.com` | Email akun Let's Encrypt | `platform/cert-manager/issuers/*` |
| `kanjeeng` | Username GitHub | `argocd/**` |
| `182.6.88.234/32` | IP publik operator (CIDR) | `terraform.tfvars`, `platform/argocd/middleware-*`, `platform/keycloak/middleware-*` |

## Versi yang dipin

| Komponen | Versi | Catatan |
|---|---|---|
| k3s | `v1.31.4+k3s1` | Variabel `k3s_version`. Kosongkan untuk channel stable |
| ArgoCD (Helm chart `argo-cd`) | `7.7.0` | Dipakai pada perintah `helm install` |
| cert-manager | `v1.16.2` | `argocd/applications/cert-manager.yaml` |
| Traefik (Helm chart) | `33.2.1` | `argocd/applications/traefik.yaml` |
| Keycloak / PostgreSQL | `26.0.7` / `16-alpine` | `platform/keycloak/` |

Jika sebuah versi sudah tidak tersedia, cari versi yang ada dengan `helm search repo <chart> --versions`, lalu perbarui `targetRevision`. Verifikasi kompatibilitas nilai Helm dengan versi yang dipilih.

## Ringkasan alur

1. `terraform apply` (folder `terraform/`), lalu buat record A wildcard `*.gitops` di Hostinger menuju Elastic IP.
2. Ambil kubeconfig dari `k3s-server`, pastikan 3 node `Ready`.
3. Pasang ArgoCD dengan Helm memakai `bootstrap/argocd-values.yaml`.
4. Push repositori ke GitHub, terapkan `argocd/projects/` dan `argocd/root-app.yaml`.
5. ArgoCD membuat cert-manager, ClusterIssuer, Traefik, Ingress ArgoCD, `simple-nginx`, dan `simple-httpd` secara berurutan (sync waves).
6. Uji akses `https://nginx.<subdomain>` dan `https://httpd.<subdomain>`.
7. Eksplorasi: NodePort, port-forward, rolling update ConfigMap, drift dan self-heal, rollback, promosi issuer ke production.
8. Level 3 (opsional): Keycloak SSO, RBAC, ApplicationSet, CI.
9. Pembersihan: `terraform destroy`, lepaskan Elastic IP, hapus record DNS.

## Catatan keamanan

- `terraform.tfstate`, `*.pem`, kubeconfig, dan token klaster **tidak boleh** masuk Git (sudah ada di `.gitignore`). Token k3s juga tersimpan di state Terraform dan User Data, sehingga cukup untuk lab tetapi bukan praktik production.
- Port 80 dan 443 terbuka ke internet (dibutuhkan Let's Encrypt HTTP-01 dan akses demo). Dashboard ArgoCD dibatasi middleware IP allowlist Traefik ke IP operator.
- Secret Keycloak dan client secret OIDC dibuat dengan `kubectl` dan tidak disimpan di Git.

## Pembersihan

```
cd terraform
terraform destroy
```

Setelah itu pastikan tidak ada Spot request aktif dan lepaskan Elastic IP bila dialokasikan terpisah:

```
aws ec2 describe-spot-instance-requests --region ap-southeast-1 --query "SpotInstanceRequests[?State=='active' || State=='open'].SpotInstanceRequestId"
```

## Pemecahan masalah singkat

| Gejala | Tindakan |
|---|---|
| Application `OutOfSync` atau `Degraded` | Buka detail di dashboard, lihat event, atau `kubectl -n argocd get applications` |
| Sertifikat tidak terbit | `kubectl get certificate,certificaterequest,order,challenge -A`, pastikan `nslookup` host mengarah ke Elastic IP dan port 80 dapat dijangkau |
| Ingress tidak mendapat alamat | Pastikan Traefik `Healthy` dan `providers.kubernetesIngress.publishedService.enabled` aktif |
| Agent tidak join | `sudo journalctl -u k3s-agent` pada agent, cek Security Group (6443, 8472/udp, 10250) |
| Login SSO gagal membaca discovery | Cek `kubectl -n argocd logs deploy/argocd-server`, pastikan jalur `/realms/gitops` tidak dibatasi allowlist |
