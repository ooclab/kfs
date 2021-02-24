NAME=ooclab/ubuntu-lab
TAG=v1.0.2
docker build -t $NAME:$TAG .
docker push $NAME:$TAG
