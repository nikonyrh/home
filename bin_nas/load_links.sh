#!/bin/bash

if [ -z "$1" ]; then
	echo "No output file given!"
	exit 1
fi

i=0
while read url; do
	i=$(($i+1))
	fname="$1_$i.mp4"
	echo "$i => $fname, $url"
	if [ -f "$fname" ]; then
		echo "Skipping..."
		continue
	fi
	youtube-dl --no-playlist -o "$fname" "$url"
done <list.txt
