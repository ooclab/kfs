#!/bin/bash

hugo
rsync -avz --progress --delete public/ k8s-1:/data/product/kfs.ooclab.com/
