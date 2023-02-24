#!/bin/bash

set -euo pipefail

# loda project root
PROJECT_ROOT=/home/boincadm/projects/loda

function copy_to_project {
  TARGET_DIR=$PROJECT_ROOT/$2
  docker cp $1 loda-boinc:$TARGET_DIR
  docker exec loda-boinc chown boincadm:boincadm $TARGET_DIR/$1
}

if ! docker exec loda-boinc test -d $PROJECT_ROOT; then
  echo "Error: project or container not found"
  exit 1
fi

# copy sources
pushd daemons > /dev/null
copy_to_project loda_assimilator.cpp bin/
copy_to_project loda_validator.cpp bin/
copy_to_project Makefile.daemons.mk bin/
popd > /dev/null

# build validator and assimilator programs
docker exec -w $PROJECT_ROOT/bin loda-boinc sudo -u boincadm -H make -f Makefile.daemons.mk

function add_daemon {
  if ! grep "$1" config.xml > /dev/null; then
    sed -i "s/.*<\\/daemons>/        <daemon>\n            <cmd>$1 <\\/cmd>\n        <\\/daemon>\n    <\\/daemons>/" config.xml
  fi
}

# register daemons
docker cp loda-boinc:$PROJECT_ROOT/config.xml .
add_daemon "make_work --wu_name wu_loda --cushion 3000 -d 3"
add_daemon "db_purge --min_age_days 10 -d 3"
add_daemon "loda_validator --app loda -d 3"
add_daemon "loda_assimilator --app loda -d 3"
copy_to_project config.xml .
rm config.xml
