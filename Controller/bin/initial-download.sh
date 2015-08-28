#!/bin/bash

k8s_version=v1.0.3
pause_version=0.8.0
flannel_version=0.5.2

# get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for NAME in celix-agent felix-agent node-provisioning; do
	echo "building and saving $NAME image"
	docker build -t "inaetics/$NAME:latest" "$DIR/../inaetics-demo/$NAME/"
	docker save -o "$DIR/../inaetics-demo/images/$NAME.tar" "inaetics/$NAME:latest"
done

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

influx_name="kubernetes/heapster_influxdb:v0.3"
docker pull "$influx_name"
docker save -o "$DIR/../images/influx.tar" "kubernetes/heapster_influxdb:v0.3"
#grafana_name="gcr.io/google_containers/heapster_grafana:v0.7"
grafana_name="grafana/grafana:2.1.0"
docker pull "$grafana_name"
docker save -o "$DIR/../images/grafana.tar" "grafana/grafana:2.1.0"
#heapster_name="gcr.io/google_containers/heapster:v0.17.0"
heapster_name="kubernetes/heapster:v0.17.0"
docker pull "$heapster_name"
docker save -o "$DIR/../images/heapster.tar" "kubernetes/heapster:v0.17.0"

