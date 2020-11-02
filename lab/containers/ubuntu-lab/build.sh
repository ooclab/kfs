NAME=ooclab/ubuntu-lab
TAG=v1.0.0
docker build -t $NAME:$TAG
docker push $NAME:$TAG
