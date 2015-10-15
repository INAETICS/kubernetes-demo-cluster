#!/bin/bash
TMPIP=`kubectl get pods | grep $1 | awk '{ print $1 }' | xargs kubectl describe pod | grep IP | awk '{ print $2 }'`
ncat --telnet $TMPIP 2019