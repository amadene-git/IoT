#!/bin/bash

sudo -s

yum install -y container-selinux selinux-policy-base
rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm


curl -sfL https://get.k3s.io | sh -
sed -i '$ d' /etc/systemd/system/k3s.service
echo "    --flannel-iface 'eth1'" >> /etc/systemd/system/k3s.service
systemctl daemon-reload
systemctl restart k3s

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl
chmod 644 /etc/rancher/k3s/k3s.yaml

