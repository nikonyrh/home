#!/bin/bash -e

if [ "$2" = "" ]; then
    >&2 echo "Usage: $0 [yyyy-mm-dd] [target]" && exit 1
fi

find /media/wrecked/gopro/DCIM/100GOPRO -name '*.MP4' -newermt "$1" | xargs cp -t "$2"


