#!/bin/bash -e


VIDEO=$1  # With x265 I usually use 25 - 35, depending on the content and purpose
shift

BIN=`dirname "$0"`
RES="2560 1440"
CONTINUE=1

while (( "$#" )) && [ $CONTINUE = 1 ]; do
    case "$1" in
        "--res")
            RES="$2 $3"
            shift 3
            ;;
        *)
            CONTINUE=0
    esac
done

$BIN/ffmpeg.sh $VIDEO 192 --codec x265 -cuda --res $RES $@

