#!/bin/bash
#
# Usage: ./docker-build.sh </dir/to/dockerfile> <remote-registry-prefix>
#
# Example: ./docker-build.sh node-agent-service 10.0.1.16:5000/inaetics
#
# needs docker command (v1.3 or later) in order to work.
#
# Copyright (C) 2015 - INAETICS <www.inaetics.org> - licensed under Apache Public License v2.

dir=$1
prefix=${2:-172.17.8.20:5000/inaetics}

# remote registries should adhere to the pattern "<host>:<port>(</path>)?"
regex="^[[:graph:]]+\:[[:digit:]]+(/[[:graph:]]+)?/?$"

if [ "$dir" == "" ] || [ ! -d "$dir" ] || [ "$prefix" == "" ] || ! [[ $prefix =~ $regex ]]; then
	echo "Convenience wrapper to build a Docker image and push it to a remote registry.

  Usage: $0 <docker-dir> <registry-prefix> [<tag name>]

  where:
    <docker-dir> is the directory containing the dockerfile to build;
    <registry-prefix> is the prefix of the *remote* docker registry, for example '10.0.1.1:5000/'
    <tag name> is optional and defaults to the directory name (the first argument).
" 
	exit 1
fi

# determine the names we should use for the docker-registry...
dir=$(echo "$dir" | sed -r 's#/$##g')
name=${3:-$dir}
name=$(echo "$name" | sed -r 's#/$##g')
remote_name=$(echo "$prefix/$name" | sed -r 's#/+#/#g')

if [[ $EUID -ne 0 ]]; then
    echo "This script might need root permissions to run..."
fi

docker build --quiet=true -t "$remote_name" $dir 2>/dev/null
docker push "$remote_name"

###EOF###
