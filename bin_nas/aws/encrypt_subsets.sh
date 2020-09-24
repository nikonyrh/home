#!/bin/bash

if [ -z "$1" ]; then
	echo "Example:"
	echo "/storage/data$ ~/bin/aws/encrypt_subsets.sh password /rapid/data/backup Kuvat"
	echo ""
	echo "Result: will create AES-encrypted subset ZIP files"
	echo ""
	exit 0
fi

echo "Passwd: $1"
echo "Target: $2"
echo "Source: $3"
echo ""

S=`du -hs "$3" | cut -f1`
echo ""
echo "Total size of $u: $S"

AES=`echo "$2/$3.sha1.aes.txt" | sed -r 's-(/[^/]+)/Upload_([0-9]+)-\1_\2\1_\2-'`
echo "$AES"

if [ -f "$AES" ]; then
	echo "AES SHA-1 exists at $AES, skipping $3"
	exit
fi

for s in $3/subset_*; do
	f=`echo $s | sed -r 's-([^/]+)/Upload_([0-9]+)/subset_(.)-\1_\2/\1_\2_\3-'`
    f="$2/$f.zip.aes"

	mkdir -p `dirname $f`

	if [ -f "$f" ]; then
		echo "Subset $s => $f (exists, skip)"
		continue
	fi

	echo "Subset $s => $f"
	~/bin/aws/encrypt_zip.sh "$s" "$1" > "$f"
done

