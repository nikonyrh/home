#!/bin/bash -e
VIDEO=25
AUDIO=96

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`

mkdir -p orig

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.hevc_nvenc.* ]]; then
        #echo "Skipping $fname (*.hevc_nvenc.*)"
        continue
    fi
    
    $SCRIPTPATH/ffmpeg.sh $VIDEO $AUDIO --codec x265 -cuda "$fname"
    mv "$fname" orig
done

