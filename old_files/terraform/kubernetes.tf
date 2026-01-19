resource "kubernetes_namespace" "python_app" {
  metadata {
    name = "python-app"
  }
}
