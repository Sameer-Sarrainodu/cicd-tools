#!/bin/bash

set -e

# ------------------------------------------------
# Resize disk from 20GB → 50GB
# ------------------------------------------------

# growpart requires this package
dnf install -y cloud-utils-growpart

# expand partition
growpart /dev/nvme0n1 4

# let LVM see new space
pvresize /dev/nvme0n1p4

# extend logical volumes
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -L +10G /dev/mapper/RootVG-homeVol
lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -l +100%FREE /dev/mapper/RootVG-varTmpVol

# grow filesystems
xfs_growfs /
xfs_growfs /home
xfs_growfs /var
xfs_growfs /var/tmp


# ------------------------------------------------
# Java
# ------------------------------------------------

yum install -y java-21-openjdk


# ------------------------------------------------
# Terraform
# ------------------------------------------------

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum install -y terraform


# ------------------------------------------------
# NodeJS
# ------------------------------------------------

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
dnf install -y nodejs

yum install -y zip


# ------------------------------------------------
# Docker
# ------------------------------------------------

yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

usermod -aG docker ec2-user


# ------------------------------------------------
# Helm
# ------------------------------------------------

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh