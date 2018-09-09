#!/bin/bash

VIDEO=$1
FPS=$2
shift 2

CODEC=x264

ARGS="-vcodec lib$CODEC -strict -2 -crf $VIDEO -c:a copy -r $FPS"
# echo $ARGS && exit 0

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r "s/\.([^\.]+)/.out_fps${FPS}_$VIDEO.$CODEC.\1/"`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    ffmpeg -i "$fname" $ARGS "$out"
done

