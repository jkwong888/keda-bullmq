resource "google_compute_global_address" "gateway" {
  project  = module.service_project.project_id
  name = "keda-bullmq"
}