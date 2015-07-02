#!/bin/bash
sleep 5
cd /home/core/inaetics-demo/images
for I in *.tar; do
	echo "loading image $I"
	docker load -i $I
	name="localhost:5000/inaetics/${I%.*}:latest"
	echo "pushing image $name"
	docker push $name &
done

cd /home/core/images
for I in pause.tar weave.tar weavetools.tar; do
	echo "loading image $I"
	docker load -i $I
done

echo "pushing kubernetes pause image"
docker push localhost:5000/google_containers/pause:0.8.0 &

echo "pushing weave images"
docker push localhost:5000/zettio/weave:0.9.0 &
docker push localhost:5000/zettio/weavetools:0.9.0 &