#!/bin/bash

# find kubernetes master
k8s_master=""
while [ "$k8s_master" == "" ]
do
  echo "waiting for kubernetes master starting"
  sleep 1
  k8s_master=`fleetctl list-units | grep "kube-apiserver.service.*active.*running" | awk '{print $2}' | sed 's/.*\///'`
done

echo "KUBERNETES_MASTER=http://$k8s_master:10260" >/etc/kubernetes.env
echo "env file written" | systemd-cat -t "create-k8s-env"

return_code=1
while [ "$return_code" != 0 ]
do
  echo "waiting for kubernetes master running"
  sleep 1
  wget "http://$k8s_master:10260" -O - &> /dev/null
  return_code=$?
done

exit 0
