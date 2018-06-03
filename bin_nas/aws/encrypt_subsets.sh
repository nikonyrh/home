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

for u in $3/Upload*/; do
	S=`du -hs "$u" | cut -f1`
	echo ""
	echo "Total size of $u: $S"

	U=`echo $u | sed -r 's,/[^_]*,,g'`
	AES="$2/$U/$U.sha1.aes.txt"

	if [ -f "$AES" ]; then
		echo "AES SHA-1 exists at $AES, skipping $U"
		continue
	fi

	for s in ${u}subset_*/; do
		f=`echo $s | sed -r 's,/[^_]*,,g'`
		f="$2/$U/$f.zip.aes"

		fDir=`dirname $f`
		if [ ! -d "$fDir" ]; then
			mkdir "$fDir"
		fi

		if [ -f "$f" ]; then
			echo "Subset $s => $f (exists, skip)"
			continue
		fi

		echo "Subset $s => $f"
		~/bin/aws/encrypt_zip.sh "$s" "$1" > "$f"
	done
done
