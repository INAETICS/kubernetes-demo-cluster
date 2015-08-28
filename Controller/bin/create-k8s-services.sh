#!/bin/bash

export $(cat /etc/kubernetes.env)
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/ace-provisioning-service.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/inaetics-viewer-service.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/influxdb-service.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/grafana-service.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/heapster-service.json
