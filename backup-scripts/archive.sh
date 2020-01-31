#!/bin/bash
set -e

backup_dir=/mnt/volume-nbg1-1/backup/
today=$(date +"%Y%m%d")
cd $backup_dir
tar -cvzf ./shared-archive/shared-$today.tgz ./shared/
