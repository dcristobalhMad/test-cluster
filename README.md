# Cluster Setup Script

This script automates the setup of a Kubernetes cluster using Kind (Kubernetes IN Docker), installs necessary components like MetalLB, NGINX Ingress Controller, cert-manager, Cilium, and deploys sample applications to check hubble.

## Prerequisites

- **kind**: Ensure that Kind (Kubernetes IN Docker) is installed. You can install it from [here](https://kind.sigs.k8s.io/docs/user/quick-start/).
- **kubectl**: Make sure kubectl, the Kubernetes command-line tool, is installed. You can install it from [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- **helm**: Helm, the package manager for Kubernetes, is required. Install it from [here](https://helm.sh/docs/intro/install/).
- **YAML Configuration File**: The script expects a YAML configuration file named `cluster-config.yaml` in the same directory as the script.

## Usage

Run the script without any arguments to set up the cluster:

```bash
./create-cluster.sh
```

## Decommissioning the Cluster

To decommission the cluster, use the following command:

```bash
./create-cluster.sh --decommission
```

## What the Script Does

- **Creates a Kind Cluster**: It creates a Kubernetes cluster named cluster-test using the configuration specified in cluster-config.yaml.
- **Installs MetalLB**: MetalLB is installed to provide bare-metal load balancing for Kubernetes clusters.
- **Installs NGINX Ingress Controller**: NGINX Ingress Controller is installed to manage ingress traffic.
- **Installs cert-manager**: cert-manager is installed to automate the management and issuance of TLS certificates.
- **Creates a ClusterIssuer**: A ClusterIssuer named letsencrypt-staging is created to issue certificates using Let's Encrypt's staging environment.
- **Installs Cilium**: Cilium, an open-source networking and security project, is installed.
- **Installs Sample Applications**: Sample applications are installed to check Cilium's functionality.
