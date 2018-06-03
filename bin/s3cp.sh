#!/bin/bash
D=nikonyrh-public/misc/
aws s3 cp --storage-class REDUCED_REDUNDANCY "$1" "s3://$D" --acl public-read
F=`echo "$1" | sed -r 's_.+/__'`
echo "https://s3-eu-west-1.amazonaws.com/$D$F"

