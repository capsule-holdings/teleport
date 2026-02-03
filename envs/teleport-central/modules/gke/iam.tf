# Service Account for Teleport
module "teleport_service_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.7.0"

  project_id   = var.project_id
  names        = ["teleport-helm"]
  display_name = "Teleport Helm Deployment"

  project_roles = [
    "${var.project_id}=>roles/datastore.owner",
    "${var.project_id}=>roles/storage.objectAdmin",
  ]

  generate_keys = true
}

# Custom IAM Roles
module "storage_bucket_creator_role" {
  source  = "terraform-google-modules/iam/google//modules/custom_role_iam"
  version = "8.2.0"

  target_level = "project"
  target_id    = var.project_id
  role_id      = "storage.bucket.creator.role"
  title        = "storage-bucket-creator-role"
  description  = "Allow creating storage buckets for Teleport session recordings"
  permissions  = ["storage.buckets.create"]

  members = [module.teleport_service_account.iam_email]
}

module "dns_updater_role" {
  source  = "terraform-google-modules/iam/google//modules/custom_role_iam"
  version = "8.2.0"

  target_level = "project"
  target_id    = var.project_id
  role_id      = "dns.updater.role"
  title        = "dns-updater-role"
  description  = "Allow cert-manager to complete ACME DNS-01 challenges"
  permissions = [
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
    "dns.changes.create",
    "dns.changes.get",
    "dns.changes.list",
    "dns.managedZones.list",
  ]

  members = [module.teleport_service_account.iam_email]
}

# Secret Manager
module "secrets" {
  source  = "GoogleCloudPlatform/secret-manager/google"
  version = "0.9.0"

  project_id = var.project_id

  secrets = [
    {
      name        = "teleport-gcp-credentials"
      secret_data = module.teleport_service_account.keys["teleport-helm"]
    }
  ]
}
