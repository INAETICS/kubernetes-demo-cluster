#!/bin/bash

# TODO
# - error handling (empty etcd values -> wait for weave config if not there (yet)?
# - provide ETCDCTL_PEERS from outside

echo "weave-config starting"

CONFIG_FILE="/etc/weave.env"

export ETCDCTL_PEERS=http://localhost:2379

# get basic configuration
initialNode=`etcdctl get weave/initialNode`
breakoutRoute=`etcdctl get weave/breakoutRoute`

# check if we already have a bridge address assigned to us
bridgeAddressCidr=`etcdctl get weave/nodes/$HOSTNAME`
success=false
if [ "$bridgeAddressCidr" = "" ];
then
	echo "no existing address found for $HOSTNAME"
	# get basic config
	bridgeAddressCidr=`etcdctl get weave/bridgeAddressCidr`
else
	echo "existing address found for $HOSTNAME: $bridgeAddressCidr"
	success=true
fi

# get next free ip
latest=`etcdctl get weave/latest`
while [ "$success" = false ] && [ "$latest" -lt 256 ];
do
	next=$(($latest + 1))

	# be sure that nobody increased the ip in the meanwhile
	result=`etcdctl set weave/latest "$next" --swap-with-value "$latest"`

	if [ "$next" = "$result" ];
	then
		success=true
		bridgeAddressCidr="${bridgeAddressCidr/x/$next}"
		etcdctl set weave/nodes/$HOSTNAME $bridgeAddressCidr
	else
		latest=`etcdctl get weave/latest`
	fi
done

if [ "$success" = true ];
then
	echo "found free ip, writing configuration to $CONFIG_FILE"
	echo "WEAVE_PEERS=$initialNode" > $CONFIG_FILE
	echo "BRIDGE_ADDRESS_CIDR=$bridgeAddressCidr" >> $CONFIG_FILE
	echo "BREAKOUT_ROUTE=$breakoutRoute" >> $CONFIG_FILE
	echo "weave-config ready"
	exit 0
else
	echo "failed getting ip for weave!"
	exit 1
fi
