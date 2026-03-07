#!/bin/bash

set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting setup"

# Minimal required tools
dnf install -y cloud-utils-growpart curl unzip zip git

# Resize disk
growpart /dev/nvme0n1 4 || true
pvresize /dev/nvme0n1p4

lvextend -L +10G /dev/mapper/RootVG-homeVol
lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -l +100%FREE /dev/mapper/RootVG-varTmpVol

xfs_growfs /home
xfs_growfs /var
xfs_growfs /var/tmp

# Java
dnf install -y java-21-openjdk

# Terraform
dnf install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# NodeJS
dnf module install -y nodejs:20

# Docker
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker ec2-user

# Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Setup complete"