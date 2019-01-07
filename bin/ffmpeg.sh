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

VIDEO=$1
AUDIO=$2
shift 2


FPS=
CUDA=
CODEC=x264
RES=
TARGET_DIR=.
ARGS=
CLR_ARGS=

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
            if [ "$CODEC" = "x265" ]; then
                # ref. https://stackoverflow.com/a/47901085/3731823
                CLR_ARGS='-x265-params range=full -dst_range 1 -pix_fmt yuv420p'
            fi
            shift 2
            ;;
        "--resolution")
            RES="-vf scale=$2:$3"
            shift 3
            ;;
        "--dir")
            TARGET_DIR=$2
            mkdir -p $TARGET_DIR
            shift 2
            ;;
        "--t")
            ARGS="$ARGS -ss 00:00:0.0 -t $2"
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

if ! [ -f "$1" ]; then
    >&2 echo "File $1 not found!" && exit 1
fi

#VIDEO_MIN=$(($VIDEO - 1))
#VIDEO_MAX=$(($VIDEO + 1))
#VIDEO_Q="-rc vbr_hq -qmin:v $VIDEO_MIN -qmax:v $VIDEO_MAX"

VIDEO_Q="-crf $VIDEO"

if [ "$CUDA" = "" ]; then
    ARGS="$ARGS -vcodec lib$CODEC -strict -2 $VIDEO_Q $CLR_ARGS -movflags faststart -b:a ${AUDIO}K $FPS $RES"
else
    # ref. http://ntown.at/de/knowledgebase/cuda-gpu-accelerated-h264-h265-hevc-video-encoding-with-ffmpeg/
    ARGS="$ARGS -c:v $CODEC $VIDEO_Q -pix_fmt yuv420p -movflags faststart -b:a ${AUDIO}K $FPS $RES"
fi


#echo $ARGS && exit 0


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
    
    #taskset 127
    $FFMPEG $CUDA -i "$fname" $ARGS "$out"
done

