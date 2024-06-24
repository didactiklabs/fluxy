resource "vault_policy" "policies" {
  for_each = fileset("${path.module}/policies", "*.hcl")
  policy   = file("policies/${each.key}")
  name     = replace(each.key, ".hcl", "")
}