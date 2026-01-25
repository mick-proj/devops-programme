# DevOps Programme

A complete CI/CD pipeline implementation using the Robot Shop microservices application, featuring automated deployment, monitoring, and observability.

## Overview

This project demonstrates is the final assignment of a DevOps course and includes the following setup:

- **Continuous Integration/Deployment**: GitHub Actions + ArgoCD GitOps workflow
- **Container Orchestration**: Kubernetes-based deployment with multi-replica services
- **Observability**: Prometheus metrics collection and Grafana visualization
- **Infrastructure as Code**: Kustomize for manifest management
- **Automated Setup**: Bootstrap script for rapid environment provisioning

## Architecture

The application consists of three microservices (note in the original robot-shop repo there are 6, while I use just 2):

- **Web**: Nginx-based frontend (3 replicas) - exposed via NodePort 30000
- **Cart**: Node.js backend service (2 replicas) - internal ClusterIP
- **Catalogue**: Node.js backend service (2 replicas) - internal ClusterIP

## Prerequisites

Before running this project, ensure you have:

1. **Kubernetes Cluster**: A running Kubernetes cluster (tested solely with k3s)
2. **Helm**: Package manager for Kubernetes ([installation guide](https://helm.sh/docs/intro/install/))
3. **GitHub Container Registry Access**:
   - Set environment variables:
     ```bash
     export GHCR_USERNAME=your_github_username
     export GHCR_TOKEN=your_github_personal_access_token
     ```

## Quick Start

### Automated Setup (Recommended)

Run the bootstrap script to automatically set up the entire infrastructure:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The bootstrap script will:
1. Create necessary namespaces (`robot-shop`, `argocd`, `monitoring`)
2. Configure GitHub Container Registry credentials
3. Install ArgoCD for GitOps
4. Deploy Prometheus and Grafana for monitoring
5. Deploy the Robot Shop application

### Manual Setup

If you prefer manual installation, follow these steps:

1. **Create namespaces**:
   ```bash
   kubectl create namespace robot-shop
   kubectl create namespace argocd
   kubectl create namespace monitoring
   ```

2. **Create GHCR secret**:
   ```bash
   kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=$GHCR_USERNAME \
     --docker-password=$GHCR_TOKEN \
     --namespace=robot-shop
   ```

3. **Install ArgoCD**:
   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
   ```

4. **Install Prometheus & Grafana**:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
     --namespace monitoring \
     --create-namespace \
     -f monitoring/prometheus/values.yaml \
     --wait
   ```

5. **Deploy application**:
   ```bash
   kubectl apply -f infrastructure/argocd/application.yaml
   ```

## Accessing Services

### ArgoCD UI

Get the admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Port-forward the ArgoCD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access at: https://localhost:8080

### Robot Shop Web Interface

Port-forward the web service:
```bash
kubectl port-forward svc/web -n robot-shop 8080:80
```

Access at: http://localhost:8080

Or if using NodePort on k3s:
```bash
# Access via node IP on port 30000
curl http://<node-ip>:30000
```

### Grafana Dashboard

Port-forward Grafana:
```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

Access at: http://localhost:3000

Default credentials: `admin` / `prom-operator`

## CI/CD Pipeline

### Workflow

The GitHub Actions CI/CD pipeline is triggered on every push to `main` that modifies the `app/` directory:

1. **Lint**: Dockerfiles are linted with Hadolint
2. **Build**: Docker images are built for web, cart, and catalogue services
3. **Push**: Images are tagged with git SHA and pushed to GitHub Container Registry
4. **Update**: Kubernetes manifests are automatically updated with new image tags
5. **Deploy**: ArgoCD detects changes and syncs to the cluster (auto-sync enabled)

### Deployment Time

- **Commit to Registry**: ~5-8 minutes
- **Commit to Production**: ~8-13 minutes

### Container Image Tags

Images are tagged with the full git commit SHA for traceability:
```
ghcr.io/mick-proj/robot-shop-web:<git-sha>
ghcr.io/mick-proj/robot-shop-cart:<git-sha>
ghcr.io/mick-proj/robot-shop-catalogue:<git-sha>
```

## Monitoring

### Prometheus

Prometheus is configured to scrape:
- Kubernetes nodes
- All pods with label `prometheus: scrape` (web, cart, catalogue)
- Kubelet metrics
- Scrape interval: 15 seconds

Configuration: `monitoring/prometheus/values.yaml`

### Grafana

Grafana is installed and connected to Prometheus as a data source. You can create custom dashboards to visualize:
- Application metrics
- Resource utilization
- Request rates and latencies
- Pod health and status

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── ci.yaml                    # GitHub Actions CI/CD pipeline
├── app/
│   ├── web/                           # Nginx frontend service
│   ├── cart/                          # Node.js cart service
│   └── catalogue/                     # Node.js catalogue service
├── infrastructure/
│   ├── kustomization.yaml             # Kustomize configuration
│   ├── base/
│   │   ├── namespace.yaml             # Namespace definition
│   │   └── secrets.yaml               # GHCR credentials
│   ├── web/
│   │   ├── deployment.yaml            # Web deployment (3 replicas)
│   │   └── service.yaml               # Web NodePort service
│   ├── cart/
│   │   ├── deployment.yaml            # Cart deployment (2 replicas)
│   │   └── service.yaml               # Cart ClusterIP service
│   ├── catalogue/
│   │   ├── deployment.yaml            # Catalogue deployment (2 replicas)
│   │   └── service.yaml               # Catalogue ClusterIP service
│   └── argocd/
│       └── application.yaml           # ArgoCD application manifest
├── monitoring/
│   └── prometheus/
│       └── values.yaml                # Prometheus Helm values
├── bootstrap.sh                       # Automated setup script
└── VALUE_STREAM_HIGH_LEVEL.md         # CI/CD value stream analysis
```

## Cleanup

To remove all resources:

```bash
kubectl delete namespace robot-shop
kubectl delete namespace argocd
kubectl delete namespace monitoring
```

## Documentation

For detailed CI/CD pipeline analysis and performance metrics, see [VALUE_STREAM_HIGH_LEVEL.md](VALUE_STREAM_HIGH_LEVEL.md).

## License

This project is for educational purposes as part of Telerik's DevOps training programme.
