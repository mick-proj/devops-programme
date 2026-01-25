#!/bin/bash
set -e

echo "🚀 DevOps Programme Setup Script"
echo "=================================="

# Configuration
NAMESPACE="robot-shop"
ARGOCD_NAMESPACE="argocd"
MONITORING_NAMESPACE="monitoring"

# Check prerequisites
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required but not installed. Aborting."; exit 1; }

# Check for required environment variables
if [ -z "$GHCR_TOKEN" ]; then
    echo "❌ GHCR_TOKEN environment variable is required"
    echo "   Set it with: export GHCR_TOKEN=your_github_token"
    exit 1
fi

if [ -z "$GHCR_USERNAME" ]; then
    echo "❌ GHCR_USERNAME environment variable is required"
    echo "   Set it with: export GHCR_USERNAME=your_github_username"
    exit 1
fi

# Step 1: Create namespaces
echo "📦 Creating namespaces..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $MONITORING_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Create GitHub Container Registry secret
echo "🔐 Creating GHCR secret..."
kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=$GHCR_USERNAME \
    --docker-password=$GHCR_TOKEN \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Install ArgoCD
echo "🔄 Installing ArgoCD..."
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE

# Step 4: Install Prometheus & Grafana
echo "📊 Installing Prometheus & Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace $MONITORING_NAMESPACE \
    --create-namespace \
    -f monitoring/prometheus/values.yaml \
    --wait

# Step 5: Deploy application via ArgoCD
echo "🚢 Deploying application via ArgoCD..."
kubectl apply -f infrastructure/argocd/application.yaml

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Get ArgoCD admin password:"
echo "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "  2. Port-forward ArgoCD UI:"
echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "  3. Access your application:"
echo "     kubectl port-forward svc/web -n robot-shop 8080:80"
echo ""
echo "  4. Access Grafana:"
echo "     kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "     Default credentials: admin / prom-operator"
echo ""
