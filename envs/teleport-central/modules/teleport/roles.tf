locals {
  # 共通設定
  common = {
    kubernetes_groups = ["teleport-admins"]
    kubernetes_users  = ["{{internal.kubernetes_users}}"]
    logins            = ["{{internal.logins}}", "root", "ubuntu", "centos"]
    wildcard_labels   = { "*" = ["*"] }
    rules             = [{ resources = ["*"], verbs = ["*"] }]
    options = {
      forward_agent   = true
      max_session_ttl = "8760h"
    }
  }

  roles = {
    root = {
      description = "Full admin access to all resources (Managed by Terraform)"
      allow = {
        kubernetes_labels      = local.common.wildcard_labels
        kubernetes_groups      = local.common.kubernetes_groups
        kubernetes_users       = local.common.kubernetes_users
        logins                 = local.common.logins
        node_labels            = local.common.wildcard_labels
        app_labels             = local.common.wildcard_labels
        db_labels              = local.common.wildcard_labels
        db_names               = ["{{internal.db_names}}", "*"]
        db_users               = ["{{internal.db_users}}", "*"]
        windows_desktop_labels = local.common.wildcard_labels
        windows_desktop_logins = ["{{internal.windows_logins}}", "*"]
        request                = { "roles" = ["*"] }
        impersonate            = { "roles" = ["*"], "users" = ["*"] }
        rules                  = local.common.rules
      }
      options = local.common.options
    }

    prd = {
      description = "Production environment access (Managed by Terraform)"
      allow = {
        kubernetes_labels = { "env" = ["prd"] }
        kubernetes_groups = local.common.kubernetes_groups
        kubernetes_users  = local.common.kubernetes_users
        logins            = local.common.logins
        node_labels       = local.common.wildcard_labels
        app_labels        = local.common.wildcard_labels
        db_labels         = local.common.wildcard_labels
        request           = { "roles" = ["*"] }
        rules             = local.common.rules
      }
      options = local.common.options
    }

    stg = {
      description = "Staging environment access (Managed by Terraform)"
      allow = {
        kubernetes_labels = { "env" = ["stg"] }
        kubernetes_groups = local.common.kubernetes_groups
        kubernetes_users  = local.common.kubernetes_users
        logins            = local.common.logins
        node_labels       = local.common.wildcard_labels
        app_labels        = local.common.wildcard_labels
        db_labels         = local.common.wildcard_labels
        rules             = local.common.rules
      }
      options = local.common.options
    }

    request_prd = {
      description = "Request access to production environment (Managed by Terraform)"
      allow = {
        request = { "roles" = ["prd"] }
      }
      options = {}
    }
  }
}

resource "teleport_role" "this" {
  for_each = local.roles

  version = "v7"

  metadata = {
    name        = each.key
    description = each.value.description
  }

  spec = {
    allow   = each.value.allow
    deny    = {}
    options = each.value.options
  }
}
