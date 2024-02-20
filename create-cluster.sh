#!/bin/bash

# Function to decommission the cluster
decommission_cluster() {
    echo "Decommissioning cluster..."
    kind delete cluster --name cluster-test
    echo "Cluster 'cluster-test' decommissioned successfully!"
}

# Function to install MetalLB
install_metallb() {
    echo "Installing MetalLB..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml
    kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    kubectl apply -f metallb-config.yaml
    echo "MetalLB installed successfully!"
}

# Function to install NGINX Ingress Controller
install_nginx_ingress() {
    echo "Installing NGINX Ingress Controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install nginx-ingress ingress-nginx/ingress-nginx
    echo "NGINX Ingress Controller installed successfully!"
}

# Function to install cert-manager
install_cert_manager() {
    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
    echo "cert-manager installed successfully!"
}

# Function to create a ClusterIssuer
create_cluster_issuer() {
    echo "Creating ClusterIssuer..."
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: cloudnativerioja@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    echo "ClusterIssuer created successfully!"
}

# Function to install Cilium
install_cilium() {
    echo "Installing Cilium..."
    helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium --version 1.15.0 \
    --namespace kube-system --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
    echo "Cilium installed successfully!"
}

# Install app to check hubble
install_apps() {
    echo "Installing apps to check hubble..."
    helm install my-podinfo podinfo/podinfo --values podinfo/values.yaml
    kubectl run curlpod --image=appropriate/curl --restart=Never --labels="app=curlpod-validport" -- watch -n 3 curl my-podinfo.default:9898
    kubectl run curlpod-invalid --image=appropriate/curl --restart=Never --labels="app=curlpod-invalidport" -- watch -n 3 curl my-podinfo.default
    echo "Apps installed successfully!"
}

# Check if kind is installed
if ! [ -x "$(command -v kind)" ]; then
  echo 'Error: kind is not installed. Install kind from https://kind.sigs.k8s.io/docs/user/quick-start/' >&2
  exit 1
fi

# Check if kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
  echo 'Error: kubectl is not installed. Install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl/' >&2
  exit 1
fi

# Check if helm is installed
if ! [ -x "$(command -v helm)" ]; then
  echo 'Error: helm is not installed. Install helm from https://helm.sh/docs/intro/install/' >&2
  exit 1
fi

# Check for command-line flags
if [ $# -gt 0 ]; then
    if [ "$1" == "--decommission" ]; then
        decommission_cluster
        exit 0
    else
        echo "Unrecognized flag: $1"
        exit 1
    fi
fi

# Check if the YAML configuration file exists
if [ ! -f "cluster-config.yaml" ]; then
  echo 'Error: cluster-config.yaml file not found.' >&2
  exit 1
fi

# Create a kind cluster using the configuration file
kind create cluster --name cluster-test --config cluster-config.yaml &

# Wait for the cluster to be ready
echo "Waiting for the cluster to be ready..."
until kubectl cluster-info &> /dev/null; do
  sleep 5
done

echo "Kind cluster 'cluster-test' created successfully!"

# Install MetalLB
install_metallb

# Install NGINX Ingress Controller
install_nginx_ingress

# Install cert-manager
install_cert_manager

# Wait to install cert-manager
echo "Waiting for cert-manager to be ready..."
until kubectl get pods --namespace cert-manager | grep Running &> /dev/null; do
  sleep 10
done
echo "cert-manager installed successfully!"

# Create a ClusterIssuer
create_cluster_issuer

# Install Cilium
install_cilium

# Install app to check hubble
NAMESPACE="kube-system"; while [ "$(kubectl get pods -n $NAMESPACE --no-headers | awk '{print $3}' | grep -c 'Running')" -ne "$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)" ]; do sleep 1; done

install_apps

echo "Setup completed successfully!"
