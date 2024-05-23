resource "google_redis_cluster" "cluster-ha" {
  project        = module.service_project.project_id

  name           = "redis-bullmq"

  shard_count    = 3
  psc_configs {
    network = data.google_compute_network.shared_vpc.id
  }

  region        = var.gke_cluster_location
  replica_count = 0

  node_type                 = "REDIS_SHARED_CORE_NANO"
  transit_encryption_mode   = "TRANSIT_ENCRYPTION_MODE_DISABLED"
  authorization_mode        = "AUTH_MODE_DISABLED"

  redis_configs = {
    maxmemory-policy    = "noeviction"
  }

  depends_on = [
    google_network_connectivity_service_connection_policy.default,
    module.service_project.enabled_apis,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_network_connectivity_service_connection_policy" "default" {
  project       = module.service_project.project_id
  name          = "mypolicy"
  location      = var.gke_cluster_location
  service_class = "gcp-memorystore-redis"
  description   = "my basic service connection policy"
  network       = data.google_compute_network.shared_vpc.id

  psc_config {
    subnetworks = [module.service_project.subnets[0].id]
  }
}

