#!/bin/bash

echo "weave-config starting"

CONFIG_FILE="/etc/weave.env"

export ETCDCTL_PEERS=http://localhost:2379

# get basic configuration
initialNode=`etcdctl get weave/initialNode`
breakoutRoute=`etcdctl get weave/breakoutRoute`

# check if we already have a bridge address assigned to us
bridgeAddressCidr=`etcdctl get weave/nodes/$HOSTNAME`
if [ "$bridgeAddressCidr" = "" ];
then
	echo "no existing address found for $HOSTNAME"
	# get basic config
	bridgeAddressCidr=`etcdctl get weave/bridgeAddressCidr`
	
	# use fixed IP, the 1 is reserved for us
	bridgeAddressCidr="${bridgeAddressCidr/x/1}"
	etcdctl set weave/nodes/$HOSTNAME $bridgeAddressCidr
else
	echo "existing address found for $HOSTNAME: $bridgeAddressCidr"
fi

echo "writing configuration to $CONFIG_FILE"
echo "WEAVE_PEERS=$initialNode" > $CONFIG_FILE
echo "BRIDGE_ADDRESS_CIDR=$bridgeAddressCidr" >> $CONFIG_FILE
echo "BREAKOUT_ROUTE=$breakoutRoute" >> $CONFIG_FILE
echo "weave-config ready"
exit 0
