#!/bin/bash
# Expand partition 2
echo ",+" | sfdisk -N 2 /dev/mmcblk0 --no-reread --force
# Resize FS
resize2fs /dev/mmcblk0p2
# Self-destruct
systemctl disable resize_pynqpi.service
rm /etc/systemd/system/resize_pynqpi.service
