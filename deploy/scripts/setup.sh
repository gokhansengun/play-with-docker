#!/bin/bash -ex

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Install dep
mkdir -p $GOPATH/bin
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

# Install necessary kernel modules
cat <<EOF >> /etc/modules
overlay
xt_ipvs
EOF

cat <<EOF >> ~/.bashrc
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

modprobe overlay
modprobe xt_ipvs

apt update -y
until apt install -y thin-provisioning-tools
do
    echo "waiting for lock to be relased"
    sleep 4
done

parted /dev/sda mklabel gpt
parted -a opt /dev/sda mkpart primary ext4 0% 100%

systemctl stop docker

pvcreate /dev/sda1
vgcreate docker /dev/sda1

lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG

lvconvert -y \
    --zero n \
    -c 512K \
    --thinpool docker/thinpool \
    --poolmetadata docker/thinpoolmeta

mkdir -p /etc/lvm/profile

cat <<EOF > /etc/lvm/profile/docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOF

lvchange --metadataprofile docker-thinpool docker/thinpool

lvs -o+seg_monitor

rm -rf /var/lib/docker

cat <<EOF > /etc/docker/daemon.json
{
    "storage-driver": "devicemapper",
    "storage-opts": [
        "dm.thinpooldev=/dev/mapper/docker-thinpool",
        "dm.use_deferred_removal=true",
        "dm.use_deferred_deletion=true"
    ],
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

# docker pull franela/dind:overlay2
# docker pull franela/play-with-docker:latest

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

docker pull franela/dind
docker pull franela/k8s
