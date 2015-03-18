#!/bin/bash

# find kubernetes master
k8s_master=""
while [ "$k8s_master" == "" ]
do
  echo "waiting for kubernetes master..."
  sleep 1
  k8s_master=`fleetctl list-units | grep "kube-apiserver.service.*active.*running" | awk '{print $2}' | sed 's/.*\///'`
done

echo "KUBERNETES_MASTER=http://$k8s_master:10260" >/etc/kubernetes.env
exit 0
