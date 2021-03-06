#!/bin/bash

VIDEO=$1
MULT=$2
FPS=$3
shift 3

CODEC=x264

CONTINUE=1
while (( "$#" )) && [ $CONTINUE = 1 ]; do
    case "$1" in
        "--codec")
            CODEC=$2
            shift 2
            ;;
        *)
            CONTINUE=0
    esac
done


ARGS="-vcodec lib$CODEC -strict -2 -crf $VIDEO -an -vf setpts=$MULT*PTS -r $FPS"
# echo $ARGS && exit 0

while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r "s/\.([^\.]+)/.out_slow_${MULT}x_$VIDEO.$CODEC.\1/"`
    
    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    ffmpeg -i "$fname" $ARGS "$out"
    #break
done

