#!/bin/bash

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r 's/\.([^\.]+)/.out.mp4/'`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    #rm -f "$out"
    
    #ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 21 -b:a 192K "$out"
    ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 23 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vf hqdn3d=7 -vcodec libx264 -strict -2 -crf 23 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vf transpose=1 -vcodec libx264 -strict -2 -crf 18 -b:a 192K "$out"
done
