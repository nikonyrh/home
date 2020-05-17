#!/bin/bash
cd "$(dirname "$(realpath "$0")")";

# The hook URL is in a separate file to avoid publishing it in GitHub
if [ ! -f webhook.txt ]; then
    >&2 echo "no $PWD/webhook.txt found!" && exit 1
fi

# We have a separate throttle for each distinct message content
FILE=`echo "$1" | sha1sum | cut -d' ' -f1`
FILE="throttle_slack_$FILE.tmp"

# Each unique message is delivered only once within this interval (in minutes)
TIME_LIMIT_MIN=120
N_FILES=`find "$FILE" -mmin "-$TIME_LIMIT_MIN" 2>/dev/null | wc -l`

if [ "$2" == "-force" ] || [ "$2" == "-f" ] || (($N_FILES == 0)); then
    # File does not exist or it is modified more than $TIME_LIMIT_MIN
    # minutes ago, let's write new content there and fire the webhook!
    date -u +'%F %H:%M:%S' > "$FILE"
    echo "$1" >> "$FILE"
    
    # Should do string escaping of $1 here...
    curl -s -X POST --data-urlencode "payload={\"text\": \"$1\"}" \
        `cat webhook.txt` > /dev/null
    echo 'Delivered!'
else
    echo 'Skipped...'
fi
