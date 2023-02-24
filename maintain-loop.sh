#!/bin/bash

while true; do
  echo $$ > $HOME/maintain.pid
  echo
  date
  bash maintain.sh
  sleep 3d
done
