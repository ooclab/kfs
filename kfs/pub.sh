#!/bin/bash

hugo
rsync -avz --progress --delete public/ ooclab-c01:/data/product/kfs.ooclab.com/
