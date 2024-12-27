#!/bin/bash

if [ -z "$(docker ps -q -f name=loda-boinc)" ]; then
  echo "Cannot backup: loda-boinc container not found"
  exit 1
fi

if ! docker exec loda-boinc test -d /home/boincadm/projects; then
  echo "Cannot backup: projects folder not found"
  exit 1
fi

ID=$(date +%y%m%d-%H%M%S)
BACKUP_DIR=$HOME/backups/$ID

if [ -d "$BACKUP_DIR" ]; then
  echo "Cannot backup: $BACKUP_DIR exists already"
  exit 1
fi

echo
echo "### BACKUP FILES ###"
docker exec -w /home/boincadm loda-boinc sudo -u boincadm -H tar -zcf projects.tar.gz projects
docker exec -w /etc loda-boinc tar -zcf apache2.tar.gz apache2
docker exec -w /etc loda-boinc tar -zcf letsencrypt.tar.gz letsencrypt

echo
echo "### BACKUP DATABASE ###"
docker exec loda-boinc bash -c "mysqldump loda | gzip > /loda.sql.gz"

echo
echo "### COPY BACKUP ###"
mkdir -p $BACKUP_DIR
docker cp loda-boinc:/home/boincadm/projects.tar.gz $BACKUP_DIR
docker cp loda-boinc:/etc/apache2.tar.gz $BACKUP_DIR
docker cp loda-boinc:/etc/letsencrypt.tar.gz $BACKUP_DIR
docker cp loda-boinc:/loda.sql.gz $BACKUP_DIR
docker exec loda-boinc rm /home/boincadm/projects.tar.gz /loda.sql.gz

while [ "$(ls -1 $HOME/backups | wc -l)" -gt 3 ]; do
  echo
  echo "### CLEAN UP ###"
  LAST=$(ls -1 $HOME/backups | sort | head -n 1)
  rm -rf $HOME/backups/$LAST
done
