#!/bin/bash
sleep 5

cd /home/core/images/all
for I in *.tar; do
	echo "loading image $I"
	docker load -i $I
done

if [ -d /home/core/images/controller ]; then
	cd /home/core/images/controller
	for I in *.tar; do
		echo "loading image $I"
		docker load -i $I
	done
fi

if [ -d /home/core/inaetics-demo/images ]; then
    cd /home/core/inaetics-demo/images
    for I in *.tar; do
	    echo "loading image $I"
	    docker load -i $I
    done
fi
