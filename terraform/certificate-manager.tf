resource "google_certificate_manager_certificate" "default" {
  project  = module.service_project.project_id
  name        = "keda-bullmq-gcp-jkwong-info"
  managed {
    domains = [
      "*.${google_certificate_manager_dns_authorization.instance.domain}",
      ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.instance.id,
      ]
  }
}

data "google_dns_managed_zone" "env_dns_zone" {
  name = "gcp-jkwong-info"
  project = data.google_project.host_project.project_id
}

resource "google_dns_record_set" "dns_auth" {
  project     = data.google_project.host_project.project_id
  name = google_certificate_manager_dns_authorization.instance.dns_resource_record.0.name
  type = google_certificate_manager_dns_authorization.instance.dns_resource_record.0.type
  ttl  = 5

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name

  rrdatas = [google_certificate_manager_dns_authorization.instance.dns_resource_record.0.data]
}

resource "google_dns_record_set" "wildcard" {
  project     = data.google_project.host_project.project_id
  name = "*.keda-bullmq.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name

  rrdatas = [google_compute_global_address.gateway.address]
}


resource "google_certificate_manager_dns_authorization" "instance" {
  project  = module.service_project.project_id
  name        = "dns-auth"
  description = "wildcard"
  domain      = "keda-bullmq.gcp.jkwong.info"
}

resource "google_certificate_manager_certificate_map" "certmap" {
  project  = module.service_project.project_id
  name     = "keda-bullmq-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "default" {
  project  = module.service_project.project_id
  name        = "wildcard-cert"
  map         = google_certificate_manager_certificate_map.certmap.name 
  certificates = [google_certificate_manager_certificate.default.id]
  matcher = "PRIMARY"
}
