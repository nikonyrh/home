#!/bin/bash -e

if ! [ `which ffmpeg 2>/dev/null` ] && [ `uname -s` != 'Linux' ]; then
    >&2 echo "Warning: FFMPEG not found, trying a hard-coded path in Windows ;)"
    FFMPEG=`find /c/nikon/vendor -name ffmpeg.exe | head -n1`
else
    FFMPEG=ffmpeg
fi

if ! [ -f "$FFMPEG" ]; then
    >&2 echo "FFMPEG not found!" && exit 1
fi

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

$FFMPEG -f concat -i fnames.txt -c copy "$fname"

#rm fnames.txt

