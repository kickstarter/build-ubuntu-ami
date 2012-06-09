#!/bin/bash -ex

# Customize your ubuntu AMI with whatever packages, compiled software,
# files, users, etc you want

# Install some packages
apt-get update
apt-get install build-essential zlib1g-dev libpcre3-dev git-core -y

# Compile some software
dir=`mktemp -d`
cd $dir
curl http://nginx.org/download/nginx-1.2.1.tar.gz | tar -zx
cd nginx-1.2.1
./configure
make install
cd /
rm -r $dir

# Do whatever!
echo "Hello world" > /hello_world.txt
