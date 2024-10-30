#!/usr/bin/env bash

# Run the ChimpStackr UI from the docker image with access to X11 server and the mnt directory. 
docker run -it --rm --gpus all -e DISPLAY=$DISPLAY -v /mnt:/mnt -v /tmp/.X11-unix:/tmp/.X11-unix stackr
