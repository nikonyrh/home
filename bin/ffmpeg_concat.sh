#!/bin/bash

fname=`echo "$1" | sed -r "s_.+/__" | sed -r "s/\.(.+)$/.concat.\1/"`

if [ -f "$fname" ]; then
	>&2 echo "$fname exists!" && exit 1
fi

echo '' > fnames.txt

while (( "$#" )); do
    echo "file '$1'" >> fnames.txt
    shift
done

sed -i -r "s_'.+/_'_" fnames.txt

ffmpeg -f concat -i fnames.txt  -c copy "$fname"
# ffmpeg -i combined.mp4 -r 30 -c:v libx264 -strict -2 -crf 15 combined.out.mp4

rm fnames.txt

