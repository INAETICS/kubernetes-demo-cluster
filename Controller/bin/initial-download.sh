#!/bin/bash

k8s_version=v1.0.3
pause_version=0.8.0
flannel_version=0.5.3

# get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for NAME in celix-agent felix-agent node-provisioning; do
	echo "pulling and saving $NAME image"
	docker pull "inaetics/$NAME:latest"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "inaetics/$NAME:latest"
done

echo "get latest bundles"
wget -O - "https://github.com/INAETICS/bundles/archive/master.tar.gz" | tar -xz -C "$DIR/../inaetics-demo/bundles" --strip=1

echo "downloading kubernetes binaries"
wget -O - "https://storage.googleapis.com/kubernetes-release/release/$k8s_version/kubernetes-server-linux-amd64.tar.gz" | tar -xz -C "$DIR/../opt/bin" --strip=3
rm "$DIR"/../opt/bin/*.docker_tag
rm "$DIR"/../opt/bin/*.tar

echo "pulling and saving pause image"
pause_name="gcr.io/google_containers/pause:$pause_version"
docker pull "$pause_name"
docker save -o "$DIR/../images/pause.tar" "$pause_name"

echo "pulling and saving flannel image"
flannel_name="quay.io/coreos/flannel:$flannel_version"
docker pull "$flannel_name"
docker save -o "$DIR/../images/flannel.tar" "$flannel_name"
