#!/bin/bash
# Final user-data / setup script for custom joindevops RHEL-9 AMI
# Tested and working 100% on RHEL 9.3 / 9.4 / 9.5 as of Nov 2025

set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1   # Full log for debugging later
echo "=== Starting joindevops RHEL-9 setup script - $(date) ==="

# ---------------------------------------------------------
# 1. Resize root disk from 20 GB → 50 GB (EBS already enlarged in AWS console)
# ---------------------------------------------------------
echo "=== Resizing filesystem ==="
lsblk

# Grow the partition (NVMe instances)
growpart /dev/nvme0n1 4 || echo "growpart already done or not needed"

# Critical step for LVM to see the new space
pvresize /dev/nvme0n1p4

# Extend logical volumes
lvextend -L +10G /dev/mapper/RootVG-homeVol
lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -l +100%FREE /dev/mapper/RootVG-varTmpVol

# Grow XFS filesystems
xfs_growfs /home
xfs_growfs /var
xfs_growfs /var/tmp

echo "=== Disk resize complete ==="
df -h / /home /var /var/tmp

# ---------------------------------------------------------
# 2. Install all tools (RHEL 9 native way)
# ---------------------------------------------------------
dnf update -y

# Java 21 (native RHEL 9 package)
dnf install -y java-21-openjdk java-21-openjdk-devel

# Terraform
dnf install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# Node.js 20 (AppStream – already enabled on RHEL 9)
dnf module install -y nodejs:20

# Useful basics
dnf install -y git unzip zip jq htop wget curl bind-utils gcc make python3-pip python3-devel openssl-devel libffi-devel maven

# Docker (official Docker CE repo – works perfectly on RHEL 9)
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker ec2-user

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh

# kubectl (latest EKS-compatible 1.33 as of Nov 2025)
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.5/2025-09-19/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

# ---------------------------------------------------------
# 3. Final touches
# ---------------------------------------------------------
echo "=== All tools installed successfully ==="
terraform --version
node --version
java --version
docker --version
helm version
kubectl version --client

echo "=== Setup complete! Rebooting in 10 seconds (recommended) ==="
sleep 10
reboot
