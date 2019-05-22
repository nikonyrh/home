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


VIDEO=$1  # With x265 I usually use 25 - 35, depending on the content and purpose
AUDIO=$2  # 96 kbps should be fine, or put 0 if you don't want any sound at all
shift 2


FPS=
CUDA=
CODEC=x264
RES=
TARGET_DIR=.
ARGS=
CLR_ARGS=
FORCE=
T0="00:00:0.0"
MOTION_BLUR=
SLOMO=
SLOMO_X=
FNAME_RES=

CONTINUE=1
while (( "$#" )) && [ $CONTINUE = 1 ]; do
    case "$1" in
        "-f")
            FORCE=-f
            shift
            ;;
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
        "--res")
            RES="-vf scale=$2:$3"
            FNAME_RES=".${3}p"
            shift 3
            ;;
        "--dir")
            TARGET_DIR=$2
            mkdir -p $TARGET_DIR
            shift 2
            ;;
        "--t0")
            T0=$2
            shift 2
            ;;
        "--t")
            ARGS="$ARGS -ss $T0 -t $2"
            shift 2
            ;;
        "--slomo")
            SLOMO=$2
            shift 2
            ;;
        "-motionblur")
            # TODO: Support for multiple "-vf" arguments
            ARGS="$ARGS -vf tblend=all_mode=average"
            shift
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


# This sets the video quality +/-1 of the target, produces smaller files for varying video content
VIDEO_MIN=$(($VIDEO - 1))
VIDEO_MAX=$(($VIDEO + 1))
VIDEO_Q="-rc vbr_hq -qmin:v $VIDEO_MIN -qmax:v $VIDEO_MAX"

# I used to use a fixed quality, maybe an useful fall-back for older devices or something?
#VIDEO_Q="-crf $VIDEO"

# Ref. https://stackoverflow.com/a/46693766/3731823
# Does not work?
#ARGS="$ARGS -vf scale=2560:1440:force_original_aspect_ratio=decrease,pad=2560:1440:(ow-iw)/2:(oh-ih)/2,setsar=1"

if [ "$SLOMO" != "" ]; then
    #MULT=`octave --eval "1 / $SLOMO" | sed -r 's/.+ //'`
    ARGS="$ARGS -vf setpts=$SLOMO*PTS"
    SLOMO_X="${SLOMO}x"
    AUDIO=0
fi

if [ "$AUDIO" = "0" ]; then
    AUDIO_ARG="-an"
else
    AUDIO_ARG="-b:a ${AUDIO}K"
fi

if [ "$CUDA" = "" ]; then
    ARGS="$ARGS -vcodec lib$CODEC -strict -2 $VIDEO_Q $CLR_ARGS -movflags faststart $AUDIO_ARG $FPS $RES"
else
    # ref. http://ntown.at/de/knowledgebase/cuda-gpu-accelerated-h264-h265-hevc-video-encoding-with-ffmpeg/
    ARGS="$ARGS -c:v $CODEC $VIDEO_Q $CLR_ARGS -pix_fmt yuv420p -movflags faststart $AUDIO_ARG $FPS $RES"
fi

#echo $ARGS && exit 0

# Example: --glob jpg
if [ "$1" == "--glob" ]; then
    $FFMPEG $FORCE $CUDA -pattern_type glob -i "*.$2" $ARGS "video_$2.out_$VIDEO.$CODEC.mp4"
    exit $?
fi


if ! [ -f "$1" ]; then
    >&2 echo "File $1 not found!" && exit 1
fi


while (( "$#" )); do
    fname="$1"
    shift
    
    out=`echo "$fname" | sed -r "s/\.([^\.]+)/.out_$SLOMO_X$VIDEO$FNAME_RES.$CODEC.\1/"`
    out="$TARGET_DIR/$out"

    if [ "$FORCE" == "" ] && [ -f "$out" ]; then
        echo "Skipping $fname ($out exists)"
        continue
    fi
    
    # Limts to 6 CPU cores, if you want to give some rest on 2 of the 4 + HT cores ;)
    #taskset 127
    $FFMPEG $FORCE $CUDA -i "$fname" $ARGS "$out"
done

