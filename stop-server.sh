#!/bin/bash

set -euo pipefail

# loda project root
PROJECT_ROOT=/home/boincadm/projects/loda

# check if container is running
LB_CONT=$(docker ps -q -f name=loda-boinc)
if [ -z "$LB_CONT" ]; then
  echo "Cannot stop: loda-boinc container not running"
  exit 1
fi

# stop server
echo
echo "### STOP SERVER ###"
docker exec -it -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/stop

# backup
bash backup.sh

# stop container
echo
echo "### STOP CONTAINER ###"
docker stop loda-boinc
