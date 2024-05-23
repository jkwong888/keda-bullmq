locals {
  gke_sa_roles = [
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/monitoring.viewer",
  ]
}

resource "random_string" "gke_nodepool_network_tag" {
  length           = 8
  special          = false
  upper            = false
}

resource "google_project_iam_member" "container_host_service_agent" {
  depends_on = [
    module.service_project.enabled_apis,
  ]

  project     = data.google_project.host_project.id
  role        = "roles/container.hostServiceAgentUser"
  member      = format("serviceAccount:service-%d@container-engine-robot.iam.gserviceaccount.com", module.service_project.number)
}

resource "google_service_account" "gke_sa" {
  project       = module.service_project.project_id
  account_id    = format("%s-sa", var.gke_cluster_name)
  display_name  = format("%s cluster service account", var.gke_cluster_name)
}

resource "google_project_iam_member" "gke_sa_role" {
  count   = length(local.gke_sa_roles) 
  project = module.service_project.project_id
  role    = element(local.gke_sa_roles, count.index) 
  member  = format("serviceAccount:%s", google_service_account.gke_sa.email)
}

resource "google_container_cluster" "primary" {
  provider = google-beta

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      //node_pool["node_count"],
      node_pool["node_count"],
    ]
  }

  depends_on = [
    module.service_project.enabled_apis,
    module.service_project.subnet_users,
    module.service_project.hostServiceAgentUser,
    google_project_iam_member.gke_sa_role,
    google_project_organization_policy.shielded_vm_disable,
    google_project_organization_policy.oslogin_disable,
  ]


  name     = var.gke_cluster_name
  location = module.service_project.subnets[0].region
  project  = module.service_project.project_id

  release_channel  {
      channel = "REGULAR"
  }

  network = data.google_compute_network.shared_vpc.self_link
  subnetwork = module.service_project.subnets[0].self_link

  enable_autopilot = true

  ip_allocation_policy {
    cluster_secondary_range_name = var.gke_subnet_pods_range_name
    services_secondary_range_name = var.gke_subnet_services_range_name
  }


  cluster_autoscaling {

    auto_provisioning_defaults {
      service_account = google_service_account.gke_sa.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }

  }

  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.gke_cluster_master_range
  }

  node_pool_auto_config {
    network_tags {
      tags= [ "b${random_string.gke_nodepool_network_tag.id}" ]
    }
  }
}

resource "google_compute_firewall" "cluster_api_webhook" {
  name    = "${var.gke_cluster_name}-allow-webhook"
  project     = data.google_project.host_project.project_id

  network = data.google_compute_network.shared_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.gke_cluster_master_range]
  target_tags = [ "b${random_string.gke_nodepool_network_tag.id}" ]
}

