resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  description = "Kubernetes Auth Backend"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend        = vault_auth_backend.kubernetes.path
  disable_iss_validation = "true"
  kubernetes_host        = "https://10.254.0.5:6443"
}

resource "vault_kubernetes_auth_backend_role" "external-secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["vault-auth"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = ["external-secrets"]
}