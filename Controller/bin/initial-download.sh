#!/bin/bash

k8s_version=v1.0.6
pause_version=0.8.0
podmaster_version=1.1
flannel_version=0.5.3
registry_version=2

pullAndSave() {
    # first arg is image, second filename
	echo "pulling and saving $1"
	docker pull "$1"
	docker save -o "$2" "$1"
}

# get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# build inaetics images
for NAME in celix-agent felix-agent node-provisioning; do
	echo "pulling and saving $NAME image"
	docker pull "inaetics/$NAME:latest"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "inaetics/$NAME:latest"
done

echo "get latest bundles"
wget -O - "https://github.com/INAETICS/bundles/archive/master.tar.gz" | tar -xz -C "$DIR/../inaetics-demo/bundles" --strip=1

echo "get kubectl"
wget -O "$DIR/../opt/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/$k8s_version/bin/linux/amd64/kubectl"

# pull and save 3rd party images
pullAndSave "gcr.io/google_containers/pause:$pause_version" "$DIR/../images/all/pause.tar"
#pullAndSave "gcr.io/google_containers/hyperkube:$k8s_version" "$DIR/../images/all/hyperkube.tar"
#pullAndSave "gcr.io/google_containers/podmaster:$pause_version" "$DIR/../images/controller/podmaster.tar"
pullAndSave "quay.io/coreos/flannel:$flannel_version" "$DIR/../images/all/flannel.tar" 
pullAndSave "registry:$registry_version" "$DIR/../images/controller/registry.tar" 
