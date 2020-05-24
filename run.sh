#! /bin/bash
set -exu

command -v docker ||
curl https://raw.githubusercontent.com/InnovAnon-Inc/repo/master/get-docker.sh | bash

sudo             -- \
nice -n +20      -- \
sudo -u `whoami` -- \
docker build -t innovanon/llvm-musl .

docker push innovanon/llvm-musl:latest || :

sudo             -- \
nice -n +20      -- \
sudo -u `whoami` -- \
docker run   -t innovanon/llvm-musl

