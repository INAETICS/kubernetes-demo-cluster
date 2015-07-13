# INAETICS Demonstrator on Kubernetes

This repository shows how the INAETICS demonstrator can run on a virtualized cluster
environment managed by Kubernetes. The principles and ideas in this demonstrator are based
on information from [1] and [2].

**NOTE**: to run this demonstrator, you need a machine capable of running Vagrant and up
to 6 virtual machines. In addition, a decent internet connection is preferable given that
this demonstrator uses remote Docker instances as well as installs Kubernetes from a
remote download site. For development of this demonstrator a laptop with 16GB of memory
and OSX 10.10 was used. In addition, this repository makes use of Git submodules, so make
sure to clone it with the `--recursive` flag, or be sure to call `git submodule init &&
git submodule update` after cloning!

## Overview

This demonstrator shows how to set up a cluster based on CoreOS, Kubernetes and Weave.
CoreOS is the host operating system, Kubernetes orchestrates Docker containers, and Weave
provides the virtual network and used by both Docker and Kubernetes. The application we
deploy is the [INAETICS demonstrator](https://github.com/INAETICS/demonstrator-cluster/).
For more information on the demonstrator itself, see the [INAETICS demonstrator user
guide](https://github.com/INAETICS/demonstrator-cluster/blob/master/user_guide.pdf).

This demonstrator consists of two parts: a set of cluster nodes that run the actual
demonstrator application, and a controller that provides the plumbing and coordinates the
deployment of the application.

### Cluster nodes

The cluster nodes (see the `Cluster` directory) consist of CoreOS systems on which Weave
and the Kubernetes binaries are installed. For this setup, we let both Weave and
Kubernetes use the *same* Etcd cluster as is used for the controller node, which means
that the controller node *must* be running before the cluster nodes are started. Once
Weave and Kubernetes are installed and started, the cluster nodes wait until they are
provisioned by Fleet as done is by the controller node.

### Controller node

The controller node (see the `Controller` directory) also consists of a CoreOS system, but
has a couple of more dependencies that it uses and responsibilities it takes care of:

1. it installs and starts a Weave service for the virtualized networking between the
   various application services;
2. it tells Fleet to install and start the various Kubernetes services onto *both* the controller and
   cluster nodes 
3. and lastly, it tells Kubernetes to setup and deploy our demonstrator application.

## Preparation

During runtime we need several Docker images and binaries. In order to be able to run offline (for demos etc.),
we need to pull / build these images and download the binaries before starting the cluster. You need a 
working Docker Engine installation for this (see http://docs.docker.com/index.html). Please execute the provided
script (assuming `$GIT_REPO` is set to the location of the kubernetes-demo-cluster repository):

    $ cd $GIT_REPO/Controller/bin
    $ ./initial-download.sh
    building and saving celix-agent image
    ...
    
The Docker images are saved to tar files. The tar files and the downloaded binaries are provisioned by vagrant
to the CoreOS host during startup. Since the Docker images are quite big, the startup can take a while.

## Running

First, we need to start the controller node. For this, we need to do:

    $ cd $GIT_REPO/Controller
    $ vagrant up && vagrant ssh
    ...
    ==> controller: Machine booted and ready!
    ...
    ==> controller: Running provisioner: shell...
        controller: Running: inline script

    CoreOS alpha (618.0.0)
    core@controller ~ $ _

After the controller node is started, it automatically proceeds and starts a number of
dependencies. One of the last services that is being started is the actual Kubernetes
services, so to get a notion on whether the controller is fully ready, we can watch the
journal of the kubernetes service (this takes a while!):

    core@controller ~ $ journalctl -fu kubernetes.service
    ...
    Mar 18 12:00:00 controller systemd[1]: Started Kubernetes Start script.

Once the Kubernetes service is up and running, you can exit journalctl with Ctrl^C and create
the Kubernetes ReplicationControllers and Services: 

    core@controller ~ $ ~/bin/create-k8s-replicationControllers.sh
    ace-provisioning-controller
    inaetics-datastore-viewer-controller
    inaetics-processor-controller
    inaetics-producer-controller
    inaetics-queue-controller
    core@controller ~ $ ~/bin/create-k8s-services.sh
    ace-provisioning-service
    inaetics-viewer-service

Note: if you want the ReplicationControllers and Services to be created automatically, set the "command" flag
of inaetics-k8s-services.service and inaetics-k8s-controllers.service in `Controller/user-data/coreos-k8s.yaml` to "start".

Now you can use the `kubectl` script to see
what is happening, but we need to tell it where the Kubernetes API server is running:

    core@controller ~ $ export $(cat /etc/kubernetes.env)
    core@controller ~ $ kubectl get services
    NAME                       LABELS                                    SELECTOR                             IP                  PORT
    ace-provisioning-service   <none>                                    name=ace-provisioning-pod            10.0.247.91         90
    inaetics-viewer-service    <none>                                    name=inaetics-datastore-viewer-pod   10.0.233.110        80
    kubernetes                 component=apiserver,provider=kubernetes   <none>                               10.0.0.2            443
    kubernetes-ro              component=apiserver,provider=kubernetes   <none>                               10.0.0.1            80

The listing above tells us that the `ace-provisioning-services` service runs on port `90`
and the `inaetics-viewer-service` runs on port `80`. Note the "odd" looking IP addresses,
these are assigned by Weave and are used for internal communication.

Note that once the controller is started, we need to start the cluster nodes. To start the
cluster nodes, we need to issue the following:

    $ cd $GIT_REPO/Cluster
    $ vagrant up
    ...
    ==> node-1: Importing base box 'coreos-alpha'...
    ...
    ==> node-2: Importing base box 'coreos-alpha'...
    ...
    ==> node-3: Importing base box 'coreos-alpha'...
    ...
    ==> node-4: Importing base box 'coreos-alpha'...
    ...
    ==> node-5: Importing base box 'coreos-alpha'...
    ...
    ==> node-5: Running provisioner: shell...
        node-5: Running: inline script

Each of the cluster nodes starts both Weave and Kubernetes after which
they are ready for action.

Once the cluster nodes are up and detected by the Kubernetes API-server, they are
automatically provisioned with the INAETICS demonstrator application. This application has
a single webpage that displays a couple of nice graphs which can be reached on the URL:

    http://172.17.8.20/

### Scaling up and down

To scale services up or down, you can use the `kubectl resize` command on the controller.
Suppose we have the following situation:

    $ cd $GIT_REPO/Controller
    $ vagrant ssh
    ...
    core@controller ~ $ export $(cat /etc/kubernetes.env)
    core@controller ~ $ kubectl get rc
    CONTROLLER                             CONTAINER(S)                          IMAGE(S)                                      SELECTOR                             REPLICAS
    ace-provisioning-controller            ace-provisioning-container            172.17.8.20:5000/inaetics/node-provisioning   name=ace-provisioning-pod            1
    inaetics-datastore-viewer-controller   inaetics-datastore-viewer-container   172.17.8.20:5000/inaetics/node-agent          name=inaetics-datastore-viewer-pod   1
    inaetics-processor-controller          inaetics-processor-container          172.17.8.20:5000/inaetics/node-agent          name=inaetics-processor-pod          3
    inaetics-producer-controller           inaetics-producer-container           172.17.8.20:5000/inaetics/node-agent          name=inaetics-producer-pod           1
    inaetics-queue-controller              inaetics-queue-container              172.17.8.20:5000/inaetics/node-agent          name=inaetics-queue-pod              1

From the last column, we can see that there are three `inaetics-processor-pods` and a
single `inaetics-producer-pod`. To increase the number of producer pods to two and
decrease the number of processor pods from three down to two we issue:

    core@controller ~ $ kubectl resize --replicas=2 rc inaetics-processor-controller
    core@controller ~ $ kubectl resize --replicas=2 rc inaetics-producer-controller
    core@controller ~ $ kubectl get rc
    CONTROLLER                             CONTAINER(S)                          IMAGE(S)                                      SELECTOR                             REPLICAS
    ace-provisioning-controller            ace-provisioning-container            172.17.8.20:5000/inaetics/node-provisioning   name=ace-provisioning-pod            1
    inaetics-datastore-viewer-controller   inaetics-datastore-viewer-container   172.17.8.20:5000/inaetics/node-agent          name=inaetics-datastore-viewer-pod   1
    inaetics-processor-controller          inaetics-processor-container          172.17.8.20:5000/inaetics/node-agent          name=inaetics-processor-pod          2
    inaetics-producer-controller           inaetics-producer-container           172.17.8.20:5000/inaetics/node-agent          name=inaetics-producer-pod           2
    inaetics-queue-controller              inaetics-queue-container              172.17.8.20:5000/inaetics/node-agent          name=inaetics-queue-pod              1

Kubernetes will automatically take care of the scheduling and starting (or stopping) of
the new pods based on the newly configured replicas.

## References

1. https://github.com/kelseyhightower/kubernetes-fleet-tutorial
2. http://weaveblog.com/2014/11/11/weave-for-kubernetes/
	 	
