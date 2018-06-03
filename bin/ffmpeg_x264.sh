#!/bin/bash

if [ -f "combined.mp4" ]; then
	>&2 echo "combined.mp4 exists!" && exit 1
fi

echo '' > fnames.txt

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r 's/\.([^\.]+)/.out.mp4/'`
    echo "file '$out'" >> fnames.txt
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    ffmpeg -i "$fname" -vcodec libx264 -strict -2 -crf 10 "$out"
done

sed -i -r "s_'.+/_'_" fnames.txt

ffmpeg -f concat -i fnames.txt  -c copy combined.mp4
# ffmpeg -i combined.mp4 -r 30 -c:v libx264 -strict -2 -crf 15 combined.out.mp4

