#!/bin/bash
set -e

backup_dir=/mnt/volume-nbg1-1/backup/
sg jupyter -c "rsync -a --update --delete-before /opt/shared/ $backup_dir/shared/"
