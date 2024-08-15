#!/bin/bash

set -euo pipefail

# build image
echo
echo "### BUILD IMAGE ###"
docker build -t loda-boinc .

# check if container is already running
LB_CONT=$(docker ps -q -f name=loda-boinc)
if [ -n "$LB_CONT" ]; then
  echo "Cannot start: loda-boinc container already running"
  exit 1
fi

# start container
echo
echo "### START CONTAINER ###"
docker run -d --rm --name loda-boinc --hostname lodaboinc -p 80:80 -p 443:443 loda-boinc:latest
sleep 10

# check status
echo
echo "### CHECK STATUS ###"
docker exec loda-boinc supervisorctl status
sleep 10

# create database user
echo
echo "### CREATE MYSQL USER ###"
DB_PW=Initial1
docker exec loda-boinc mysql -e "CREATE USER 'boincadm'@'localhost' IDENTIFIED BY '$DB_PW';"
docker exec loda-boinc mysql -e "GRANT ALL ON *.* TO 'boincadm'@'localhost';"

# get last backup id
BACKUP_ID=
if [ -d "$HOME/backups" ]; then
  BACKUP_ID=$(ls -1 "$HOME/backups" | sort | tail -n 1)
fi

# loda project root
PROJECT_ROOT=/home/boincadm/projects/loda

function copy_to_project {
  TARGET_DIR=$PROJECT_ROOT/$2
  docker cp $1 loda-boinc:$TARGET_DIR
  docker exec loda-boinc chown boincadm:boincadm $TARGET_DIR/$1
}

if [ -n "$BACKUP_ID" ]; then

  echo
  echo "### RESTORE ###"
  echo
  BACKUP_DIR=$HOME/backups/$BACKUP_ID
  docker cp $BACKUP_DIR/projects.tar.gz loda-boinc:/home/boincadm/
  docker cp $BACKUP_DIR/apache2.tar.gz loda-boinc:/etc/
  docker cp $BACKUP_DIR/letsencrypt.tar.gz loda-boinc:/etc/
  docker cp $BACKUP_DIR/loda.sql.gz loda-boinc:/
  docker exec -w /home/boincadm loda-boinc tar -xf projects.tar.gz
  docker exec -w /etc loda-boinc tar -xf apache2.tar.gz
  docker exec -w /etc loda-boinc tar -xf letsencrypt.tar.gz
  docker exec loda-boinc mysql -e "CREATE DATABASE loda"
  docker exec loda-boinc bash -c "gunzip -c /loda.sql.gz | mysql loda"
  docker exec loda-boinc rm /home/boincadm/projects.tar.gz /loda.sql.gz

else

  echo
  echo "### MAKE LODA PROJECT ###"
  docker exec -w /usr/local/boinc/tools loda-boinc sudo -u boincadm ./make_project \
            --db_host localhost \
            --db_user boincadm \
            --db_passwd $DB_PW \
            --no_query \
            --url_base 'https://boinc.loda-lang.org' \
            --project_root $PROJECT_ROOT \
            loda LODA

  # project html
  pushd html > /dev/null
  copy_to_project project.inc html/project/
  copy_to_project project_description.php html/project/
  copy_to_project schedulers.txt html/user/

  pushd dl > /dev/null
  docker exec loda-boinc sudo -u boincadm mkdir -p $PROJECT_ROOT/html/dl
  copy_to_project gzip.exe html/dl/
  popd > /dev/null

  pushd img > /dev/null
  for image in *.png; do
    copy_to_project $image html/user/img/
  done
  popd > /dev/null

  pushd ops > /dev/null
  copy_to_project badge_assign_loda.php html/ops/
  popd > /dev/null

  popd > /dev/null

  # set admin password
  if [ -z "${ADMIN_PW+x}" ]; then
    echo -n "Enter new admin password: "
    read ADMIN_PW
  fi
  docker exec loda-boinc sudo -u boincadm htpasswd -cb $PROJECT_ROOT/html/ops/.htpasswd admin $ADMIN_PW

  # project metadata
  copy_to_project project.xml .
  docker exec -it -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/xadd

  # apache configuration for the project; restart apache
  docker exec loda-boinc ln -s $PROJECT_ROOT/loda.httpd.conf /etc/apache2/sites-enabled/
  docker cp html/www_redirect.html loda-boinc:/var/www/html/index.html
  docker exec loda-boinc apache2ctl -k graceful

  # certbot
  docker exec -it loda-boinc certbot --apache

  # install daemons
  bash install-daemons.sh

fi

# restart apache 
docker cp html/www_redirect.html loda-boinc:/var/www/html/index.html
docker exec loda-boinc apache2ctl -k graceful

# cron tab & start
docker exec loda-boinc sudo -u boincadm crontab $PROJECT_ROOT/loda.cronjob
docker exec -it -w $PROJECT_ROOT loda-boinc sudo -u boincadm -H ./bin/start
