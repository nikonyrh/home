#!/bin/bash
mkdir -p orig

while (( "$#" )); do
    fps=`ffprobe -v 0 -of csv=p=0 -select_streams 0 -show_entries stream=r_frame_rate "$1" | \
        sed -r 's/(.+)/round(\1)/' | octave | sed -r 's/.+ //'`
    
    out=`echo "$1" | sed -r "s/\.([^\.]+)/.fps${fps}.\1/"`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    cp "$1" "$out"
    mv "$1" orig
    shift
done

