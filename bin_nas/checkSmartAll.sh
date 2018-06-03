echo /dev/disk/by-id/ata-* | xargs -n1 echo | grep -v -- -part | xargs -n1 sudo smartctl -A
