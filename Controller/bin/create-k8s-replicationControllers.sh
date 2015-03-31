#!/bin/bash

export $(cat /etc/kubernetes.env)
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/ace-provisioning-controller.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/inaetics-datastore-viewer-controller.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/inaetics-processor-controller.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/inaetics-producer-controller.json
/opt/bin/kubectl create -f /home/core/inaetics-demo/k8s/inaetics-queue-controller.json
