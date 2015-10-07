#!/bin/bash

. /opt/bin/export-k8s-env.sh
kubectl scale --replicas=0 rc/inaetics-queue-controller
kubectl scale --replicas=1 rc/inaetics-queue-celix-controller
