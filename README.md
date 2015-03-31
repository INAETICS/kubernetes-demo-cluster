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
2. it also starts a Docker registry service which is used by the cluster nodes to obtain
   the Docker images they should run. After the Docker registry service is started, the
   Docker images used by the INAETICS demonstrator are built and pushed to it;
3. it tells Fleet to install and start the various Kubernetes services onto *both* the controller and
   cluster nodes 
4. and lastly, it tells Kubernetes to setup and deploy our demonstrator application.

**NOTE**: given that Kubernetes and a couple of Docker images need to be downloaded and
build, it takes a while before the controller is fully up and running!


## Running

First, we need to start the controller node. For this, we need to do (assuming
`$GIT_REPO` is set to the location of the kubernetes-demo-cluster repository):

    $ cd $GIT_REPO/Controller
    $ vagrant up && vagrant ssh
    ...
    ==> controller: Machine booted and ready!
    ...
    ==> controller: Running provisioner: shell...
        controller: Running: inline script

    CoreOS alpha (618.0.0)
    core@controller ~ $ _

After the controller node is started, it automatically proceeds and downloads a number of
dependencies. One of the last services that is being started is the actual Kubernetes
services, so to get a notion on whether the controller is fully ready, we can watch the
journal of the kubernetes service (this takes a while!):

    core@controller ~ $ journalctl -fu kubernetes.service
    ...
    Mar 18 12:00:00 controller systemd[1]: Started Kubernetes Start script.

Once the Kubernetes service is up and running, you can use the `kubectl` script to see
what is happening, but we need to tell it where the Kubernetes API server is running:

    core@controller ~ $ export $(cat /etc/kubernetes.env)
    core@controller ~ $ kubectl get services
    NAME                       LABELS                                    SELECTOR                             IP                  PORT
    ace-provisioning-service   <none>                                    name=ace-provisioning-pod            10.0.247.91         90
    inaetics-viewer-service    <none>                                    name=inaetics-datastore-viewer-pod   10.0.233.110        80
    kubernetes                 component=apiserver,provider=kubernetes   <none>                               10.0.0.2            443
    kubernetes-ro              component=apiserver,provider=kubernetes   <none>                               10.0.0.1            80

The listing above tells us that the `ace-provisioning-services` service runs on port `80`
and the `inaetics-viewer-service` runs on port `90`. Note the "odd" looking IP addresses,
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

Each of the cluster nodes needs to download both Weave and Kubernetes binaries after which
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
	 	
