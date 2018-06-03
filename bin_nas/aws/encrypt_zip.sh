#!/bin/bash

if [ -z "$3" ]; then
	#echo "With compression" 1>&2
	C=""
else
	#echo "No compression" 1>&2
	C="-0"
fi

S=`du -hs "$1" | cut -f1`
echo "Size of '$1': $S" 1>&2

zip - -q $C -r "$1" | ~/bin/aws/encrypt.sh stdin "$2"
