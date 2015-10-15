# INAETICS Demonstrator on Kubernetes

This repository shows how the INAETICS demonstrator can run on a virtualized cluster
environment managed by Kubernetes. The principles and ideas in this demonstrator are based
on information from [1].

**NOTE**: to run this demonstrator, you need a machine capable of running Vagrant and up
to 6 virtual machines. In addition, a decent internet connection is preferable at install time,
given that the demonstrator needs to pull several Docker images, github repositories and 3rd party binaries.
During runtime no internet connection is needed.
For development of this demonstrator a laptop with 16GB of memory
and OSX 10.10 was used. In addition, this repository makes use of Git submodules, so make
sure to clone it with the `--recursive` flag, or be sure to call `git submodule init &&
git submodule update` after cloning!

## Overview

This demonstrator shows how to set up a cluster based on CoreOS, Flannel and Kubernetes.
CoreOS is the host operating system, Flannel provides the virtual network used by both
Docker and Kubernetes, and Kubernetes orchestrates Docker containers. The application we
deploy is the [INAETICS demonstrator](https://github.com/INAETICS/kubernetes-demo-cluster/).
For more information on the demonstrator itself, see the [INAETICS demonstrator user
guide](https://github.com/INAETICS/demonstrator-cluster/blob/master/user_guide.pdf).

This demonstrator consists of two parts: a set of cluster nodes that run the actual
demonstrator application, and a controller that provides the plumbing and coordinates the
deployment of the application.

### Cluster nodes

The cluster nodes (see the `Cluster` directory) consist of CoreOS systems on which Flannel
and the Kubernetes binaries are installed. For this setup, we let both Flannel and
Kubernetes use the *same* Etcd cluster as is used for the controller node, which means
that the controller node *must* be running before the cluster nodes are started. Once
Flannel and Kubernetes are installed and started, the cluster nodes wait until they are
provisioned by Kubernetes by the controller node.

### Controller node

The controller node (see the `Controller` directory) also consists of a CoreOS system, but
has a couple of more dependencies that it uses and responsibilities it takes care of:

1. it installs and starts the Flannel service for the virtualized networking between the
   various application services;
2. it runs the Kubernetes master components (apiserver, controller, scheduler)
3. it runs a docker registry for the inaetics images
4. and lastly, it tells Kubernetes to setup and deploy our demonstrator application.

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
to the CoreOS hosts during startup. Since the Docker images are quite big, the startup can take a while.

## Running

First, we need to start the controller node. For this, we need to do:

    $ cd $GIT_REPO/Controller
    $ vagrant up && vagrant ssh
    ...
    ==> controller: Machine booted and ready!
    ...
    ==> controller: Running provisioner: shell...
        controller: Running: inline script

    CoreOS alpha (815.0.0)
    core@controller ~ $ _

After the controller node is started, it automatically proceeds and starts a number of
dependencies. The last services that is being started is the actual inaetics
service, so to get a notion on whether the controller is fully ready, we can watch the
journal of the inaetics service (this takes a while!):

    core@controller ~ $ journalctl -fu inaetics.service
    ...
    Oct 08 08:31:30 controller systemd[1]: Started INAETICS demonstrator Kubernetes services and controllers.

Once the inaetics service is up and running, you can exit journalctl with Ctrl^C.

The inaetics service starts several kubernetes services and replication controllers
respectivly pods. You can use the `kubectl` script to see what is happening.

You can list the kubernetes services by:

    core@controller ~ $ kubectl get services
    NAME                       LABELS                                    SELECTOR                             IP(S)          PORT(S)
    ace-provisioning-service   <none>                                    name=ace-provisioning-pod            10.3.188.132   90/TCP
    inaetics-viewer-service    <none>                                    name=inaetics-datastore-viewer-pod   10.3.21.191    80/TCP
    kubernetes                 component=apiserver,provider=kubernetes   <none>                               10.3.0.1       443/TCP

The listing above tells us that the `ace-provisioning-service` service runs on port `90`
and the `inaetics-viewer-service` runs on port `80`. Note the "odd" looking IP addresses,
these are assigned by Flannel and are used for internal communication.

You can list the kubernetes replication controllers by:

    core@controller ~ $ kubectl get rc
    CONTROLLER                             CONTAINER(S)                          IMAGE(S)                     SELECTOR                             REPLICAS
    ace-provisioning-controller            ace-provisioning-container            inaetics/node-provisioning   name=ace-provisioning-pod            1
    inaetics-datastore-viewer-controller   inaetics-datastore-viewer-container   inaetics/felix-agent         name=inaetics-datastore-viewer-pod   1
    inaetics-processor-celix-controller    inaetics-processor-celix-container    inaetics/celix-agent         name=inaetics-processor-celix-pod    0
    inaetics-processor-controller          inaetics-processor-container          inaetics/felix-agent         name=inaetics-processor-pod          0
    inaetics-producer-controller           inaetics-producer-container           inaetics/felix-agent         name=inaetics-producer-pod           1
    inaetics-queue-controller              inaetics-queue-container              inaetics/felix-agent         name=inaetics-queue-pod              1

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

Each of the cluster nodes starts both Flannel and Kubernetes after which
they are ready for action. Note: since several docker images are copied to each node, the startup is
quite slow.

Once the cluster nodes are up and registered themself at the Kubernetes API-server, they are
automatically provisioned with the INAETICS demonstrator application.

You can check the status of the provisioning by listing the detected nodes and installed pods
on the controller node:

    core@controller ~ $ kubectl get nodes
    NAME          LABELS                               STATUS
    172.17.8.31   kubernetes.io/hostname=172.17.8.31   Ready
    172.17.8.32   kubernetes.io/hostname=172.17.8.32   Ready
    ...
    
    core@controller ~ $ kubectl get pods -o=wide
    NAME                                         READY     STATUS    RESTARTS   AGE       NODE
    ace-provisioning-controller-2n4w5            1/1       Running   0          19m       172.17.8.32
    inaetics-datastore-viewer-controller-nk1bn   1/1       Running   0          19m       172.17.8.31
    inaetics-processor-celix-controller-amtur    1/1       Running   0          1m        172.17.8.35
    inaetics-processor-celix-controller-t1phl    1/1       Running   0          44s       172.17.8.32
    inaetics-processor-controller-0n554          1/1       Running   0          3m        172.17.8.31
    inaetics-processor-controller-7jap8          1/1       Running   0          54s       172.17.8.34
    inaetics-producer-controller-m871n           1/1       Running   0          19m       172.17.8.34
    inaetics-queue-controller-9jcpk              1/1       Running   0          19m       172.17.8.33


This application has a webpage that displays a couple of nice graphs and a dashboard which can be reached on the URL:

    http://172.17.8.20/
    
### Scaling up and down

The number of processors is scaled automatically by the demonstrator by monitoring the queue utiliation.
The number of producers can be scaled on the dashboard.
The dashboard also shows the number of actual running and requested processors and producers.
You can also use `kubectl get rc` and `kubectl get pods` for monitoring what kubernetes is doing.

## References

1. https://github.com/kelseyhightower/kubernetes-fleet-tutorial