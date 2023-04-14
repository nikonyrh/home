#!/bin/bash -e
D=nikonyrh-public/misc/

while (( "$#" )); do
    F=`echo "$1" | sed -r 's_.+/__'`
    echo "https://s3-eu-west-1.amazonaws.com/$D$F"
    
    aws s3 cp --storage-class STANDARD_IA "$1" "s3://$D" --acl public-read
    shift
done
