#!/bin/bash -e
# Ref. https://askubuntu.com/a/749561/430574

: '
unzip $1
rm mimetype stack.xml Thumbnails/thumbnail.png
rmdir Thumbnails
mv mergedimage.png data/__0.png
cd data
'

if [ $1 == '-r' ]; then
    fnames=$(ls -- *.png | LC_ALL=C sort -r)
    shift
else
    fnames=$(ls -- *.png | LC_ALL=C sort)
fi

base=`echo $1 | sed -r 's/\.[^.]+$//'`

ix=1
for fname in $fnames; do
    convert -quality 95 "./$fname" "${base}_${ix}.jpg"
    ix=$(($ix + 1))
done

