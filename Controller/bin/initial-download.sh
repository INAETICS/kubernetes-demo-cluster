#!/bin/bash

weave_version=0.9.0
k8s_version=v0.21.1
pause_version=0.8.0

# get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for NAME in celix-agent felix-agent node-provisioning; do
	echo "building and saving $NAME image"
	docker build -t "inaetics/$NAME:latest" "$DIR/../inaetics-demo/$NAME/"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "inaetics/$NAME:latest"
done

echo "pulling and saving weave images"
weave_name="zettio/weave:$weave_version"
weavetools_name="zettio/weavetools:$weave_version"
docker pull "$weave_name"
docker save -o "$DIR/../images/weave.tar" "$weave_name"
docker pull "$weavetools_name"
docker save -o "$DIR/../images/weavetools.tar" "$weavetools_name"

echo "downloading weave scripts"
wget -N -P "$DIR/../opt/bin" "https://github.com/weaveworks/weave/releases/download/v$weave_version/weave"
wget -N -P "$DIR/../opt/bin" "https://raw.githubusercontent.com/slintes/weave-demos/master/poseidon/weave-helper"

echo "downloading kubernetes binaries"
wget -O - "https://storage.googleapis.com/kubernetes-release/release/$k8s_version/kubernetes-server-linux-amd64.tar.gz" | tar -xz -C "$DIR/../opt/bin" --strip=3
rm "$DIR"/../opt/bin/*.docker_tag
rm "$DIR"/../opt/bin/*.tar

echo "pulling and saving pause image"
pause_name="gcr.io/google_containers/pause:$pause_version"
docker pull "$pause_name"
docker save -o "$DIR/../images/pause.tar" "$pause_name"

