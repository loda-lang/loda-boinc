#!/bin/bash

# loda project root
PROJECT_ROOT=/home/boincadm/projects/loda

function copy_to_project {
  TARGET_DIR=$PROJECT_ROOT/$2
  docker cp $1 loda-boinc:$TARGET_DIR
  docker exec loda-boinc chown boincadm:boincadm $TARGET_DIR/$1
}

if [ -x "$(command -v docker)" ] && [ -n "$(docker ps -q -f name=loda-boinc)" ]; then
  echo
  echo "### RUN IN CONTAINER ###"
  set -e

  # copy templates to container
  pushd templates > /dev/null
  docker exec loda-boinc sudo -u boincadm mkdir -p $PROJECT_ROOT/templates
  copy_to_project loda_in templates
  copy_to_project loda_out templates
  popd > /dev/null

  # copy this script to container
  copy_to_project job.xml .
  copy_to_project prepare-versions.sh .
  copy_to_project version_template.xml .

  # execute this script in the container
  docker exec -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H bash prepare-versions.sh
  docker exec -w $PROJECT_ROOT loda-boinc rm prepare-versions.sh job.xml version_template.xml

  # create dummy input file
  if ! docker exec loda-boinc test -f $PROJECT_ROOT/input; then
    echo
    echo "### CREATE INPUT ###"
    echo 1 > input
    copy_to_project input .
    docker exec -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H $PROJECT_ROOT/bin/stage_file input
    rm input
  fi
  exit 0
fi

# check required commands
for cmd in curl jq unzip; do
  if ! [ -x "$(command -v $cmd)" ]; then
    echo "Error: $cmd is not installed" >&2
    exit 1
  fi
done

set -e

LODA_REL=$(curl -fsS https://api.github.com/repos/loda-lang/loda-cpp/releases/latest | jq -r .tag_name)
LODA_URL="https://github.com/loda-lang/loda-cpp/releases/download/$LODA_REL"
WRAPPER_URL="https://boinc.berkeley.edu/dl"

LV=${LODA_REL#v}
APP_VERSION=$(printf "%02d%02d%02d" "$(echo $LV | cut -d. -f1)" "$(echo $LV | cut -d. -f2)" "$(echo $LV | cut -d. -f3)")
APP_DIR="$HOME/apps/loda/$APP_VERSION"
if [ -d "$HOME/projects/loda" ]; then
  APP_DIR="$HOME/projects/loda/apps/loda/$APP_VERSION"
fi

function fetch_loda {
  curl -fsSLo $2 $LODA_URL/$1
  chmod oug+x $2
}

function fetch_wrapper {
  curl -fsSLO $WRAPPER_URL/wrapper_$1.zip
  unzip -q -o wrapper_$1.zip
  rm wrapper_$1.zip wrapper_$1.pdb 2> /dev/null || true
  # linux arm64 wrapper is in a subfolder
  if [ -d wrapper* ]; then
    mv wrapper*/wrapper* tmp_wrapper
    rm -r wrapper*
    mv tmp_wrapper wrapper_$1
    chmod oug+x wrapper_$1
  fi
}

function make_version {
  VERSION_DIR="$APP_DIR/$1"
  echo $VERSION_DIR
  [ -d $VERSION_DIR ] && rm -r $VERSION_DIR
  mkdir -p $VERSION_DIR
  pushd $VERSION_DIR > /dev/null
  fetch_loda $2 $3
  fetch_wrapper $4
  WRAPPER=$(ls wrapper*)
  JOB_PHYSICAL="loda_job_${APP_VERSION}.xml"
  popd > /dev/null
  cp job.xml "${VERSION_DIR}/$JOB_PHYSICAL"
  cat version_template.xml \
    | sed "s/WRAPPER_PHYSICAL_NAME/$WRAPPER/g" \
    | sed "s/LODA_PHYSICAL_NAME/$3/g" \
    | sed "s/JOB_PHYSICAL_NAME/$JOB_PHYSICAL/g" \
    > "${VERSION_DIR}/version.xml"
}

echo
echo "### PREPARE APP VERSIONS ###"
make_version "windows_x86_64" "loda-windows.exe" "loda-$APP_VERSION-windows.exe" "26016_windows_x86_64"
make_version "x86_64-pc-linux-gnu" "loda-linux-x86" "loda-$APP_VERSION-linux-x86" "26015_x86_64-pc-linux-gnu"
make_version "x86_64-apple-darwin" "loda-macos" "loda-$APP_VERSION-macos" "26017_universal-apple-darwin"
make_version "aarch64-unknown-linux-gnu" "loda-linux-arm64" "loda-$APP_VERSION-linux-arm64" "linux_arm64_26018"
