This document describes the steps needed to deploy your own application on an INAETICS system.

Even if you want to run your system on bare-metal it is advised to start with the vagrant environment to test your distributed OSGi application!
See www.inaetics.org and download the UserGuide for the INAETICS 1.1 demonstrator: 
http://www.inaetics.org/wp-content/uploads/2015/10/IN-Installationandsetupguideof1.1demonstrator-091015-1338-6.pdf

Step 1: Setup machines with CoreOS, Etcd, Docker and Kubernetes
* 1.a Install the kubernetes-demo-cluster (this repo, see link above for detailed instructions)
This results in two virtual machine environments:
      - a Controller, a single CoreOS VM managed by vagrant
      - a Cluster, five CoreOS VMs managed by vagrant that use the Controller

If developed correctly you application consists of a number of components (with service interfaces)
For the application deployment it has to be determined which components need to be deployed together and which need to be
deployed separate to achieve scalability. Each set of components has to be deployed in a separate docker container, 
either in a felix-agent if it is a JAVA component or in a celix-agent if it is a C component.
Because INAETICS still lacks a generic Coordinator, we give the containers hostnames like celix_1, felix_2 etc. These are 
used later in ACE to determine which bundles need to be provisioned to which container. Because Kubernetes is used to
deploy the docker containers (the INAETICS agents) it is instructed to generate PODS for each specific component.
If necessary, multiple components can be combined in a single POD (run on the same INAETICS agent).

Step 2: Split application over multiple OSGi frameworks (INAETICS agents)
* 2.a in Controller/inaetics-demo/k8s are json configuration files for Kubernetes. Add your own ... controller files for each
component that you have. The existing inaetics-... files can almost completely be copied, just adapt the POD name and the hostname.
Most likely your application has some interface with the external world, either a webinterface or a service that is exposed.
For now we make the assumption that this external interface only has to be available on the Host machine running the virtual images.
(Note: the vagrant configuration defines an hostonly adapter, otherwise a bridge set-up is needed)
* 2.b in Controller/inaetics-demo/k8s are json configuration files for services that externally reachable, e.g. the ACE webinterface.
Add your own service files to this (be aware of unique port numbers on the Controller node)

Step 3: instruct Kubernetes which PODS to start
* 3.a adapt Controller/user-data/coreos-k8s.yaml for your own set of Controllers and Services
Don not remove the ACE provisioning Controller and Service

Step 4: instruct the Provisioning server ACE how to distribute the bundles
* 4.a Put your own bundles (JAR files) in Controller/inaetics-demo/node-provisioning/bundles/default-resources
* 4.b Write your own default-mapping.gosh script (keep all the features that are not marked with demo)

Step 5: Start and test!



For bare metal installation the following prerequisites replace step 1 above
Controller Machine (not fail-safe at the moment)
Needed: 
- Etcd2 server configured as leader
- Docker
- Kubernetes master (scheduler, api-server, proxy)

Cluster Machines:
- Etcd2 either as proxy or standby
- Docker
- Kubernetes (proxy and node manager)
- Docker images for node agents (network mount point or pre-installed)
- Software bundles used by ACE (network mount point or pre-installed)
 
Optionally kubernetes can be started inside docker with the hyperkube image, see our master branch
Optionally ACE can be started on the Controller, see bare-metal-installation repo
Optionally a Docker registry is run on the Controller, see our master branch
