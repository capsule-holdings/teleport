# Project Default Network Tier
resource "google_compute_project_default_network_tier" "default" {
  network_tier = "PREMIUM"
}

# VPC Network Module
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "13.1.0"

  project_id   = var.project_id
  network_name = var.vpc_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = "10.0.0.0/16"
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "10.2.0.0/16"
      },
    ]
  }

  ingress_rules = [
    {
      name          = "${var.vpc_name}-allow-ssh"
      description   = "Allow SSH from anywhere"
      priority      = 65534
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
    {
      name          = "${var.vpc_name}-allow-internal"
      description   = "Allow internal traffic on the default network"
      priority      = 65534
      source_ranges = ["10.0.0.0/9"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        },
      ]
    },
    {
      name          = "${var.vpc_name}-allow-icmp"
      description   = "Allow ICMP from anywhere"
      priority      = 65534
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "icmp"
        ports    = []
      }]
    },
  ]
}

# External IP for NAT
resource "google_compute_address" "nat_ip" {
  count        = var.nat_ip_count
  name         = format("gip-%02d", count.index)
  region       = var.region
  address_type = "EXTERNAL"
}

# Cloud NAT Module
module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "6.0.0"

  project_id    = var.project_id
  region        = var.region
  router        = var.router_name
  name          = "default"
  create_router = true
  network       = module.vpc.network_id

  # Match existing configuration
  router_asn       = null
  min_ports_per_vm = "0"

  nat_ips                            = google_compute_address.nat_ip[*].self_link
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetworks = [
    {
      name                     = module.vpc.subnets["${var.region}/${var.subnet_name}"].id
      source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE"]
      secondary_ip_range_names = []
    }
  ]
}

# Private IP for VPC Peering
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_id
}

# Service Networking Connection
resource "google_service_networking_connection" "default" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
