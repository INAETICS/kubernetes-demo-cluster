#!/bin/bash
sleep 5
cd /home/core/inaetics-demo/images
for I in *.tar; do
	echo "loading image $I"
	docker load -i $I
done

cd /home/core/images
for I in *.tar; do
	echo "loading image $I"
	docker load -i $I
done
