#!/bin/bash

sudo -s

yum install -y container-selinux selinux-policy-base
rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm



# token -> cat /var/lib/rancher/k3s/server/node-token on Server node
curl -sfL https://get.k3s.io | K3S_TOKEN=<token> K3S_URL=https://<ip>:6443 sh -


sed -i '$ d' /etc/systemd/system/k3s-agent.service
echo "    --flannel-iface 'eth1'" >> /etc/systemd/system/k3s-agent.service
systemctl daemon-reload
systemctl restart k3s-agent

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