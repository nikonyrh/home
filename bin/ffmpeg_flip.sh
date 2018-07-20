#!/bin/bash

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.flip.* ]]; then
        echo "Skipping $fname (*.flip.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r 's/\.([^\.]+)/.flip.\1/'`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    #rm -f "$out"
    
    #ffmpeg -i "$fname" -vcodec libx264 -vf hflip,vflip -strict -2 -crf 16 -codec:a copy "$out"
    ffmpeg -i "$fname" -c copy -metadata:s:v:0 rotate=180 -codec:a copy "$out"
done

