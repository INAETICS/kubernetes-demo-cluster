#!/bin/bash

K8S_MASTER=http://127.0.0.1:10080

# wait for api server
echo "waiting for kubernetes api server..."
return_code=1
while [ "$return_code" != 0 ]
do
  sleep 1
  wget "$K8S_MASTER" -O - &> /dev/null
  return_code=$?
  echo "still waiting for kubernetes api server..."
done
echo "kubernetes api server is running"

# create env file for inaetics service
echo "creating k8s env file"
echo "KUBERNETES_MASTER=$K8S_MASTER" >/etc/kubernetes.env

# create kube config file for core user
echo "creating k8s config for core user"
exec sudo -u core /bin/bash - << eof
  kubectl config set-cluster inaetics --server="$K8S_MASTER"
  kubectl config set-context inaetics --cluster=inaetics
  kubectl config use-context inaetics
eof