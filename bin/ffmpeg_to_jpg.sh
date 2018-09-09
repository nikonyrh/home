#!/bin/bash

mkdir -p jpg
cd jpg

while (( "$#" )); do
    mkdir -p $1
    cd "$1"
    
    rm *.jpg
    
    ffmpeg -i "../../$1" -qscale:v 5 "$1.f%07d.jpg"
    
    cd ..
    shift
done

