#!/bin/bash -ex

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

mkdir -p $GOPATH/src/github.com/play-with-docker
cd $GOPATH/src/github.com/play-with-docker
git clone https://github.com/gokhansengun/play-with-docker.git
cd play-with-docker && dep ensure -v

# TODO: gseng - differentiate between pwd and pwk
# git checkout -b pwk origin/pwk && docker-compose up -d

# pwd case
docker-compose up -d

