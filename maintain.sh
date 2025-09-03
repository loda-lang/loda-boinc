#!/bin/bash

# loda project root
PROJECT_ROOT=/home/boincadm/projects/loda

echo
echo "### STOP DAEMONS ###"
docker exec -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/stop

echo
echo "### PURGE LOGS ###"
docker exec loda-boinc bash -c "rm $PROJECT_ROOT/log_lodaboinc/*.log"
docker exec loda-boinc bash -c "rm $PROJECT_ROOT/log_lodaboinc/*.out"

echo
echo "### PURGE STATS ###"
docker exec loda-boinc bash -c "rm -r $PROJECT_ROOT/html/stats_*"

echo
echo "### PURGE ARCHIVES ###"
docker exec loda-boinc bash -c "rm $PROJECT_ROOT/archives/*"

# create a backup
source backup.sh

# echo
# echo "### CREATE WORK ###"
# docker exec -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/create_work --appname loda --wu_name wu_loda input

echo
echo "### START DAEMONS ###"
docker exec -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/start
