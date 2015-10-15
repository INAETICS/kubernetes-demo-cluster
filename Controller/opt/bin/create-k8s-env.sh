#!/bin/bash

K8S_MASTER=http://localhost:10080

# create env file for inaetics service
echo "KUBERNETES_MASTER=$K8S_MASTER" >/etc/kubernetes.env

# create kube config file for core user
exec sudo -u core /bin/bash - << eof
  kubectl config set-cluster inaetics --server="$K8S_MASTER"
  kubectl config set-context inaetics --cluster=inaetics
  kubectl config use-context inaetics
eof

return_code=1
while [ "$return_code" != 0 ]
do
  echo "waiting for kubernetes master running"
  sleep 1
  wget "http://$K8S_MASTER" -O - &> /dev/null
  return_code=$?
done

exit 0