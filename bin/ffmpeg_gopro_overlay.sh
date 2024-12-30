#!/bin/bash
rm -f out.mp4

mkdir -p orig
rm -f out.mp4

while (( "$#" )); do
    FNAME="$1"
    PREFIX=$(echo "$FNAME" | sed -r 's/[_.].+//')
    SPEED=$(echo "speed/${PREFIX}*.mp4")
    shift
    
    if ! $(test -e $SPEED); then
        >&2 echo "Skipping $FNAME, $SPEED not found"
        continue
    fi
    
    >&2 echo "Processing $FNAME"

    ffmpeg -hwaccel cuvid -i "$FNAME" -i $SPEED \
        -filter_complex '[1:v]colorkey=0x00FF00:0.4:0.2[ckout];[0:v][ckout]overlay[out]' -map '[out]' \
        -c:v h264_nvenc -rc vbr_hq -qmin:v 23 -qmax:v 25 -pix_fmt yuv420p -movflags faststart out.mp4

    ffmpeg -i out.mp4 -i "$FNAME" -c copy -map 0:v:0 -map 1:a:0 out2.mp4
    mv "$FNAME" orig
    mv out2.mp4 "${PREFIX}_speed.mp4"
    rm -f out.mp4
done


