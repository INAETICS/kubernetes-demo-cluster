#!/bin/bash

sleep 5

for DIR in /home/core/images/all /home/core/images/controller /home/core/images/cluster /home/core/inaetics-demo/images; do
	if [ -d "$DIR" ]; then
		cd "$DIR"
		for TARFILE in *.tar; do
			echo "loading image $TARFILE"
			docker load -i "$TARFILE"
		done
	fi
done
