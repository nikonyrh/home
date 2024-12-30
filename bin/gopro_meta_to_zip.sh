#!/bin/bash -e

mkdir -p speed_txt

while (( "$#" )); do
    echo "Starting $1"
    docker run --rm -it -v "$PWD:/media" runsascoded/gpmf-parser "/media/$1" -a -f > "speed_txt/$1.txt"
    shift
done

echo "Data extraction done, creating a zip"
rm -f speed_txt.zip

cd speed_txt
zip -7 ../speed_txt.zip -r .
cd ..

