#!/bin/bash

k8s_version=v1.1.1 # see https://github.com/kubernetes/kubernetes/releases
pause_version=0.8.0 # see https://github.com/kubernetes/kubernetes/blob/master/build/pause/Makefile#L4
podmaster_version=1.1 # see https://github.com/kubernetes/kubernetes/blob/master/docs/admin/high-availability/podmaster.yaml#L9
flannel_version=0.5.3 # search on https://coreos.com/releases/
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
	remote_name="inaetics/$NAME:latest"
	local_name="172.17.8.20:5000/$remote_name"
	docker pull "$remote_name"
	docker tag -f "docker.io/$remote_name" "$local_name"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "$local_name"
done

echo "get latest bundles"
wget -O - "https://github.com/INAETICS/bundles/archive/master.tar.gz" | tar -xz -C "$DIR/../inaetics-demo/bundles" --strip=1

echo "get kubectl"
wget -O "$DIR/../opt/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/$k8s_version/bin/linux/amd64/kubectl"

# pull and save 3rd party images
pullAndSave "gcr.io/google_containers/pause:$pause_version" "$DIR/../images/all/pause.tar"
pullAndSave "gcr.io/google_containers/hyperkube:$k8s_version" "$DIR/../images/all/hyperkube.tar"
#pullAndSave "gcr.io/google_containers/podmaster:$pause_version" "$DIR/../images/controller/podmaster.tar"
pullAndSave "quay.io/coreos/flannel:$flannel_version" "$DIR/../images/all/flannel.tar" 
pullAndSave "registry:$registry_version" "$DIR/../images/controller/registry.tar" 

# only when using ELK
#pullAndSave "slintes/elasticsearch:latest" "$DIR/../images/cluster/elasticsearch.tar"
#pullAndSave "logstash:latest" "$DIR/../images/cluster/logstash.tar"
#pullAndSave "slintes/kibana:latest" "$DIR/../images/cluster/kibana.tar"
