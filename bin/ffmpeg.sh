#!/bin/bash

VIDEO=$1
AUDIO=$2
shift 2

ARGS="-vcodec libx264 -strict -2 -crf $VIDEO -b:a ${AUDIO}K"

ARGS="$ARGS -r 30"

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r "s/\.([^\.]+)/.out_$VIDEO.\1/"`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    ffmpeg -i "$fname" $ARGS "$out"
    
    #rm -f "$out"
    
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 18 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 21 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 23 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 25 -b:a 92K "$out"
    
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -vf scale=1920:-1 -crf 25 -b:a 128K "$out"
    
    #ffmpeg -i "$fname" -vf hqdn3d=7 -vcodec libx264 -strict -2 -crf 23 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vf transpose=1 -vcodec libx264 -strict -2 -crf 18 -b:a 192K "$out"
done

