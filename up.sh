#!/bin/bash
rsync -avz /home/shang/test/test/dist/ qft-xg:/home/ubuntu/mt-h5/dist --delete --exclude=.git --exclude=up.sh --exclude=table-img