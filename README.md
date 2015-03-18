# INAETICS Demonstrator on Kubernetes

This repository shows how the INAETICS demonstrator can run on a virtualized cluster
environment managed by Kubernetes. The principles and ideas in this demonstrator are based
on information from [1] and [2].

**NOTE**: to run this demonstrator, you need a machine capable of running Vagrant and up
to 6 virtual machines. For development of this demonstrator a laptop with 16GB of memory
and OSX 10.10 was used.


## Overview

This demonstrator shows how to set up a cluster based on CoreOS, Kubernetes and Weave.
CoreOS is the host operating system, Kubernetes orchestrates Docker containers, and Weave
provides the virtual network and used by both Docker and Kubernetes. The application we
deploy is the [INAETICS demonstrator](https://github.com/INAETICS/demonstrator-cluster/).
For more information on the demonstrator itself, see the [INAETICS demonstrator user
guide](https://github.com/INAETICS/demonstrator-cluster/blob/master/user_guide.pdf).

This demonstrator consists of two parts: a set of worker nodes that run the actual
demonstrator application, and a controller that provides the plubming and coordinates the
deployment of the application.

The coreos-userdata files provides the configuration of CoreOS for each VM. Vagrant is
used for provisioning of needed scripts and configuration files:

- on the EtcdAndFleet VM Fleet is used in order to provision Kubernetes to the Cluster VMs, see scripts/startK8sUnits.sh and units/*
- also on the EtcdAndFleet VM Kubernetes is used to deploy an Apache ACE server and several ACE targets with different configurations to the Cluster VMs, see scripts/startAceAndAgents.sh and k8s/*
- on the Cluster VMs docker and weave are configured for creating and using the virtual network


## Dependencies

This demo tries to start an INAETICS provisioning service and several INAETICS agents. It depends on a running IANETICS docker-registry-service and docker-image-builder, which build and provide the needed docker images (see https://github.com/INAETICS). You can run the AptCacherAndDockerRegistry VM for this:

`cd AptCacherAndDockerRegistry`  
`vagrant up`  

- check http://172.17.8.21:5000/v1/search for available images (will take some minutes, the VM downloads Dockerfiles from github, builds the images, and finally provides them in the docker registry)


## Usage

### Start etcd and fleet cluster (clustersize is 5)

`cd EtcdAndFleet`  
`vagrant up`  

- this starts CoreOS within Vagrant, running etcd, fleet, installs kubernetes and starts ACE service and ACE agents, IP is 172.17.8.20

### Start some cluster nodes

`cd Cluster`  
`vagrant up`  

- this starts 5 CoreOS cluster nodes within Vagrant, each registering at our EtcdAndFleet machine

### Check status

`cd EtcdAndFleet`  
`vagrant ssh`  

`fleetctl list-machines`

- this lists all machines under control of fleet

`fleetctl list-units`

- this lists all available / deployed fleet units

`. scripts/ekm.sh`

- this exports the url of the kubernetes API server, needed for kubectl

`kubectl get minions` (or short `mi`)  
`kubectl get pods` (or short `po`)  
`kubectl get replicationControllers` (or short `rc`)  
`kubectl get list services` (or short `se`)  

- lists all deployed minions, pods, replicationControllers, services


### check provisioning and demonstrator application

open http://172.17.8.31 for accessing ACE (user: d, password: f)

- thanks to the kubernetes provisioning service this works on all cluster node IPs (configured in EtcdAndFleet/k8s/ace-provisioning-service.json)

open the demonstrator viewer on http://172.17.8.31:90

- this is also a kubernetes service, see EtcdAndFleet/k8s/amdatu-viewer-service.json

### scaling

`cd EtcdAndFleet`  
`vagrant ssh`  
`. scripts/ekm.sh`  

`kubectl resize --replicas=<NR> replicationcontrollers <CONTROLLER>`

- replace &lt;NR&gt; with the desired number of instances, and &lt;CONTROLLER&gt; with amdatu-producer-controller or amdatu-processor-controller

## References

1. https://github.com/kelseyhightower/kubernetes-fleet-tutorial
2. http://weaveblog.com/2014/11/11/weave-for-kubernetes/
	 	
