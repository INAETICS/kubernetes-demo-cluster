# Debugging the Inaetics Demonstrator

This document should help you debugging the demonstrator in case of problems.

## Debugging CoreOS / systemd

The demonstrator depends on several systemd units, which load docker images into the local docker cache,
install a docker registry, start the overlay network, start kubernetes, and finally start the demonstrator.

The first indication that a systemd unit failed is a warning message when log in to CoreOS, e.g.:

    $ vagrant ssh
    CoreOS alpha (835.0.0)
    Update Strategy: No Reboots
    Failed Units: 1
      elk.service

This assumes that you log in after the boot process finished. In order to find out manually what services failed,
use the ```systemctl``` command:

    core@controller ~ $ systemctl --state=failed
      UNIT        LOAD   ACTIVE SUB    DESCRIPTION
    ● elk.service loaded failed failed ELK service and controller

Now you want to know why the service failed:

    core@controller ~ $ systemctl status elk
    ● elk.service - ELK service and controller
       Loaded: loaded (/etc/systemd/system/elk.service; static; vendor preset: disabled)
       Active: failed (Result: exit-code) since Wed 2015-10-21 12:06:56 UTC; 10min ago
      Process: 1861 ExecStart=/opt/bin/kubectl create -f /home/core/k8s/inaetics/elk-service.json (code=exited, status=1/FAILURE)
     Main PID: 1861 (code=exited, status=1/FAILURE)
    
    Oct 21 12:06:56 controller systemd[1]: Starting ELK service and controller...
    Oct 21 12:06:56 controller systemd[1]: elk.service: Main process exited, code=exited, status=1/FAILURE
    Oct 21 12:06:56 controller systemd[1]: Failed to start ELK service and controller.
    Oct 21 12:06:56 controller systemd[1]: elk.service: Unit entered failed state.
    Oct 21 12:06:56 controller systemd[1]: elk.service: Failed with result 'exit-code'.
    Oct 21 12:06:56 controller kubectl[1861]: error: could not read an encoded object from /home/core/k8s/inaetics/elk-service.json: unable to connect to a server ...on refused
    Oct 21 12:06:56 controller kubectl[1861]: error: no objects passed to create
    Hint: Some lines were ellipsized, use -l to show in full.

This should help you to fix the problem. See ```systemctl --help``` for more commands and options.

In order to see full logs, use the ```journalctl``` command. Some useful options are:

- -b: only logs since last boot  
- -u &lt;unit&gt;: only logs of given systemd unit  
- -e: start showing last logs instead of first logs  
- -f: follow the log  

## Debugging kubernetes

The demonstrator comes with a preconfigured ```kubectl``` binary, the kubernetes command line tool. Some useful commands are:
 
 - ```kubectl get no```: list nodes
 - ```kubectl get se```: list services
 - ```kubectl get rc```: list replication controllers
 - ```kubectl get po -o=wide```: list pods (inclusive IPs)
 - ```kubectl get ev```: list events
 - ```kubectl describe <resourcetype> <resourceid>```: show status of given resource, e.g. ```kubectl describe pod inaetics-producer-controller-0pj7t```
 - ```kubectl delete <resourcetype> <resourceid>```: delete given resource, pods will be restarted by their replication controller
 
## Debugging the demonstrator

When all pods are running, but the demonstrator still has problems, there is a problem with the demonstrator itself.
In order to see the logs of a pod use ```kubectl logs <resourceid>```.
You can log in into a pod with ```kubectl exec -it <podid> bash```.

The felix components run the felix console, which can be accessed on port 2019. There is a helper script which finds the
needed ip address and logs you in. It takes any unique part of the pod id as argument, e.g. ```telnet.sh viewer```.

The felix components also have Java remote debugging enabled on port 8000. In order to access that port from your local
demonstrator development environment, you can create a temporary kubernetes service, e.g.:
```kubectl expose rc inaetics-datastore-viewer-controller --name=javadebug --port=99 --target-port=8000 --public-ip=172.17.8.20 ```.
Now you can point the remote debugger to 172.17.8.20:99, and kubernetes will proxy the traffic to the corresponding container.

If you want to restart all demonstrator containers, use ```sudo systemctl restart inaetics``` 

## ELK

In order to view all logs (currently only of felix components) at one place you can enable logging to an ELK stack:

- Elasticsearch is the database where all logs are stored
- Logstash receives all logs from the components
- Kibana is a search UI for elasticsearch

In order to enable logging to ELK you have to

- uncomment the elk images in Controller/bin/initial-download.h and execute the script
- add ```["identity"="org.inaetics.demonstrator.java_impl.logsender" "version"="0"]``` to "felix_agent_base" in
Controller/inaetics-demo/bundles/default-mapping.gosh (Note: this will be overridden when running the initial-download.sh script again!).
- uncomment "command: start" for the elk.service in Controller/user-data/coreos-k8s.yaml.
- increase memory of the Cluster VMs to at least 1536MB, see Cluster/Vagrantfile. Maybe you also want to decrease the number of
VMs to 4 or even 3 in order to compensate the increased memory usage.

After a restart of the demonstrator (cluster nodes start slower now, because the ELK images have to be provisioned to the VM)
you can first check if elasticsearch gets logs:

- browse to elasticsearch, http://172.17.8.20:82/_plugin/marvel
- verify that there is a "logstash-yyy-mm-dd" index (indices are shown at the bottom)

If the logstahs index is present, you can search the logs using kibana:

- browse to kibana, http://172.17.8.20:81
- you have to "Configure an index pattern": chose "time" as "Time-field name", leave the rest at their defaults, click "Create"
- click on "Discover" on the top menu
- on the left side, below "Available Fields", add host, bundle, level and msg
- enter your search in the search bar below the top menu. E.g. if you want to see only logs of wiring of producers, enter "host:*producer* AND bundle:*wiring*"

When you are ready with debugging and disable ELK, you probably want to delete the tarred ELK images in Controller/images/cluster in order to accelerate
vagrant provisioning.