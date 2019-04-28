#!/bin/bash -e

if [ "$1" = "" ]; then
    >&2 echo "Usage: $0 [yyyy-mm-dd] [target]" && exit 1
fi

if [ "$1" = "-" ]; then
    DATE=`date +%Y-%m-%d`
else
    DATE=$1
fi

find /media/wrecked/gopro/DCIM/100GOPRO -name '*.MP4' -newermt "$DATE" | xargs cp -t "${2:-.}"

