#!/bin/bash -e

# TODO: Is there a more standard way for cross-patform bash scripts?
FFMPEG=`which ffmpeg || echo ''`

if ! [ -f "$FFMPEG" ]; then
    if [ `uname -s` != 'Linux' ]; then
        >&2 echo "Warning: FFMPEG not found, trying a hard-coded path in Windows ;)"
        FFMPEG=`find /c/nikon/vendor -name ffmpeg.exe | head -n1`
        
        if ! [ -f "$FFMPEG" ]; then
            >&2 echo "FFMPEG not found!" && exit 1
        fi
    else
        >&2 echo "'ffmpeg' not found (expecting ffmpeg to be found from \$PATH)!" && exit 1
    fi
fi


out=`echo "$1" | sed -r "s_.+/__" | sed -r "s/\.(.+)$/.concat.\1/"`

if [ -f "$out" ]; then
	>&2 echo "$out exists!" && exit 1
fi

echo '' > fnames.txt

while (( "$#" )); do
    echo "file '$1'" >> fnames.txt
    shift
done

# sed -i -r "s_'.+/_'_" fnames.txt

$FFMPEG -f concat -i fnames.txt -c copy "$out"

