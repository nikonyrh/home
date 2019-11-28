#!/bin/bash -e


VIDEO=$1  # With x265 I usually use 25 - 35, depending on the content and purpose
shift

BIN=`dirname "$0"`
$BIN/ffmpeg.sh $VIDEO 192 --codec x265 -cuda --res 2560 1440 $@

