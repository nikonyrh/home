#!/bin/bash

VIDEO=$1
AUDIO=$2
shift 2

FPS=
CUDA=
CODEC=x264
RES=
TARGET_DIR=.

CONTINUE=1
while (( "$#" )) && [ $CONTINUE = 1 ]; do
    case "$1" in
        "--fps")
            FPS="-r $2"
            shift 2
            ;;
        "--codec")
            if [ "$CUDA" != "" ]; then
                >&2 echo "--codec must be defined before -cuda flag!" && exit 1
            fi
            
            CODEC=$2
            shift 2
            ;;
        "--resolution")
            RES="-vf scale=$2:$3"
            shift 3
            ;;
        "--dir")
            TARGET_DIR=$2
            shift 2
            ;;
        "-cuda")
            CUDA='-hwaccel cuvid'
            
            if [ "$CODEC" == x264 ]; then
                CODEC=h264_nvenc
            else
                CODEC=hevc_nvenc
            fi
            
            shift
            ;;
        *)
            CONTINUE=0
    esac
done

if [ "$CUDA" = "" ]; then
    ARGS="-vcodec lib$CODEC -strict -2 -crf $VIDEO -movflags faststart -b:a ${AUDIO}K $FPS $RES"
else
    VIDEO_MIN=$(($VIDEO - 1))
    VIDEO_MAX=$(($VIDEO + 1))
    
    # ref. http://ntown.at/de/knowledgebase/cuda-gpu-accelerated-h264-h265-hevc-video-encoding-with-ffmpeg/
    ARGS="-c:v $CODEC -rc vbr_hq -qmin:v $VIDEO_MIN -qmax:v $VIDEO_MAX -pix_fmt yuv420p -movflags faststart -b:a ${AUDIO}K $FPS $RES"
fi

# echo $ARGS && exit 0


while (( "$#" )); do
    fname="$1"
    shift
    
    if [[ "$fname" = *.out.* ]]; then
        echo "Skipping $fname (*.out.*)"
        continue
    fi
    
    out=`echo "$fname" | sed -r "s/\.([^\.]+)/.out_$VIDEO.$CODEC.\1/"`
    out="$TARGET_DIR/$out"

    if [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    ffmpeg $CUDA -i "$fname" $ARGS "$out"
    
    #ffmpeg -i "$fname" -vf hqdn3d=7 -vcodec libx264 -strict -2 -crf 23 -b:a 192K "$out"
    #ffmpeg -i "$fname" -vf transpose=1 -vcodec libx264 -strict -2 -crf 18 -b:a 192K "$out"
done

