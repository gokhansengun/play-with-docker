#!/bin/bash -ex

# TODO: gseng - how to avoid duplication
export GOROOT=/usr/local/go
export GOPATH=/home/vagrant/go
export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin

cd $GOPATH/src/github.com/play-with-docker

sudo mkdir $GOPATH/pkg
sudo chown vagrant:vagrant $GOPATH/pkg
dep ensure -v

# TODO: gseng - differentiate between pwd and pwk
# git checkout -b pwk origin/pwk && docker-compose up -d
git checkout master && docker-compose up -d
