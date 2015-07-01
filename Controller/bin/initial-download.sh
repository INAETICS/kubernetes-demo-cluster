#!/bin/bash

KUBE_VERSION=v0.18.2
WEAVE_VERSION=v0.9.0

mkdir -p opt/bin
/usr/bin/wget -O - "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/kubernetes-server-linux-amd64.tar.gz" | tar -xz -C opt/bin --strip=3;
chmod 0755 opt/bin/kube*

/usr/bin/wget -N -P opt/bin https://github.com/zettio/weave/releases/download/$WEAVE_VERSION/weave;
/usr/bin/wget -N -P opt/bin https://raw.github.com/slintes/weave-demos/master/poseidon/weave-helper;
chmod 0755 opt/bin/weave*
