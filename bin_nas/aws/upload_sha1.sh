#!/bin/sh
f=`echo "$1" | sed -r 's,.+/,,g'`
aws s3 cp "$1" "s3://wrecked-backups/index/$f"
