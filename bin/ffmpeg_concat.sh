#!/bin/bash

if [ -f "combined.mp4" ]; then
	>&2 echo "combined.mp4 exists!" && exit 1
fi

echo '' > fnames.txt

while (( "$#" )); do
    echo "file '$1'" >> fnames.txt
    shift
done

sed -i -r "s_'.+/_'_" fnames.txt

ffmpeg -f concat -i fnames.txt  -c copy combined.mp4
# ffmpeg -i combined.mp4 -r 30 -c:v libx264 -strict -2 -crf 15 combined.out.mp4

rm fnames.txt

