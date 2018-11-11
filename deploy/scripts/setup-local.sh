#!/bin/bash -ex

export GOROOT=/usr/local/go
export GOPATH=/home/vagrant/go
export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin

# Install dep
mkdir -p $GOPATH/bin
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

# Install necessary kernel modules
cat <<EOF >> /etc/modules
overlay
xt_ipvs
EOF

cat <<EOF >> /home/vagrant/.bashrc
export GOROOT=/usr/local/go
export GOPATH=/home/vagrant/go
export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin
EOF

modprobe overlay
modprobe xt_ipvs

apt update -y
until apt install -y thin-provisioning-tools
do
    echo "waiting for lock to be relased"
    sleep 4
done

systemctl stop docker

cat <<EOF > /etc/docker/daemon.json
{
  "dns": [
    "172.18.0.1",
    "8.8.8.8",
    "10.0.0.2"
  ]
}
EOF

systemctl start docker

AD_IP=$(hostname -I | cut -d' ' -f2)
docker swarm init --advertise-addr=${AD_IP}

cat <<EOF >> /etc/sysctl.conf
net.ipv4.neigh.default.gc_thresh3 = 8192
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh1 = 4096
fs.inotify.max_user_instances = 10000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65000
net.netfilter.nf_conntrack_tcp_timeout_established = 600
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 1
EOF

sysctl -p

# docker pull franela/dind
# docker pull franela/k8s
