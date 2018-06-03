#!/bin/bash

#if [ "$#" -ne 1 ]; then
#	echo "1 2 3 4 5 6" | xargs -n1 -P0 ~/bin/benchmarkDrive.sh
#	exit 0
#fi

#FNAME="outfile$1"
#rm -f $FNAME && dd if=/dev/zero of=$FNAME bs=10M count=200 conv=fdatasync && sync
#dd if=$FNAME of=/dev/null conv=fdatasync

FIND=". -type f -print0"

FILES=`find . -type f | wc -l`
BITS=`find $FIND | du -s | cut -f1`
HUM=`find $FIND | du -sh | cut -f1`
THREADS=5

echo "$FILES files, ${BITS}kb ($HUM), processing with $THREADS threads" 1>&2

echo "Starting..."
time find $FIND | xargs -0 -n1 "-P$THREADS" md5sum
