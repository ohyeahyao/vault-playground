locals {
  app_namespace = "app"
}

resource "kubernetes_namespace" "app-namespace" {
  metadata {
    annotations = {
      name = local.app_namespace
    }

    name = local.app_namespace
  }
}
