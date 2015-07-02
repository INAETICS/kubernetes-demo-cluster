#!/bin/bash

# get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for NAME in celix-agent felix-agent node-provisioning; do
	echo "building and saving $NAME image"
	docker build -t "localhost:5000/inaetics/$NAME:latest" "$DIR/../inaetics-demo/$NAME/"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "localhost:5000/inaetics/$NAME:latest"
done

echo "building and saving pause image"
pause_version=0.8.0
docker pull "gcr.io/google_containers/pause:$pause_version"
docker tag "gcr.io/google_containers/pause:$pause_version" "localhost:5000/google_containers/pause:$pause_version"
docker save -o "$DIR/../images/pause.tar" "localhost:5000/google_containers/pause:$pause_version"

echo "building and saving weave images"
weave_version=0.9.0
docker pull "zettio/weave:$weave_version"
docker tag "zettio/weave:$weave_version" "localhost:5000/zettio/weave:$weave_version"
docker save -o "$DIR/../images/weave.tar" "localhost:5000/zettio/weave:$weave_version"
docker pull "zettio/weavetools:$weave_version"
docker tag "zettio/weavetools:$weave_version" "localhost:5000/zettio/weavetools:$weave_version"
docker save -o "$DIR/../images/weavetools.tar" "localhost:5000/zettio/weavetools:$weave_version"
