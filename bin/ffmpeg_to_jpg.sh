#!/bin/bash

mkdir -p jpg
cd jpg

ARGS='-vsync 0 -qscale:v 5'

while (( "$#" )); do
    mkdir -p $1
    cd "$1"
    
    rm *.jpg
    
    # ffmpeg -r 1 -i "../../$1" $ARGS "$1.f%07d.jpg"
    ffmpeg -r 1 -i "../../$1" $ARGS -vf select="not(mod(n\,7))" "$1.f%07d.jpg"
    
    cd ..
    shift
done

