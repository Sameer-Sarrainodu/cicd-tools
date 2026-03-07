#!/bin/bash

set -e

# ------------------------------------------------
# Resize disk from 20GB → 50GB
# ------------------------------------------------

dnf install -y cloud-utils-growpart

# expand partition
growpart /dev/nvme0n1 4

# resize LVM physical volume
pvresize /dev/nvme0n1p4

# extend logical volumes
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -l +100%FREE /dev/mapper/RootVG-varTmpVol

# grow filesystems
xfs_growfs /
xfs_growfs /var
xfs_growfs /var/tmp


# ------------------------------------------------
# Jenkins installation
# ------------------------------------------------

curl -o /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2023.key

dnf install -y java-21-openjdk jenkins

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins