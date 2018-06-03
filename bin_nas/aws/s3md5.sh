#!/bin/bash
# s3md5  Copyright (C) 2013
#        Antonio Espinosa <aespinosa at teachnova dot com>
#
# This file is part of s3md5 by Teachnova (www.teachnova.com)
#
# s3md5 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# s3md5 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with s3md5.  If not, see <http://www.gnu.org/licenses/>.

VERSION='1.0'
DEBUG=0

##################################################################
# s3md5 paths
root_path() {
   SOURCE="${BASH_SOURCE[0]}"
   DIR="$( dirname "$SOURCE" )"
   while [ -h "$SOURCE" ]
   do
     SOURCE="$( readlink "$SOURCE" )"
     [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
   done
   DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

   echo "$DIR"
}

is_integer() {
   local min="$2"
   local max="$3"

   if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
      return 1
   fi

   if [ -n "$2" ] && [ $2 -gt $1 ]; then return 1; fi
   if [ -n "$3" ] && [ $3 -lt $1 ]; then return 1; fi

   return 0
}

license_show() {
   cat << LICENSE
s3md5 v$VERSION
Copyright (C) 2013 Antonio Espinosa <aespinosa@teachnova.com> - TeachNova
This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to redistribute it GPLv3 license conditions. Read LICENSE.md for more details.

LICENSE
}

help_show() {
   license_show
   cat << HELP
Calculates the Etag/S3 MD5 Sum of a file, using the same algorithm that S3 uses on multipart uploaded files.
Specially usefull on files bigger than 5GB uploaded using multipart S3 API. You can check file integrity
comparing S3 Etag with the value returns by 's3md5 15 file'

Usage : $APP <size> <file>

- size : Multipart chunk size in MB
- file : Calculate Etag of this file

Example : Use 15 MB chunk size (as default in s3cmd .s3cfg config file)
   ~> s3md5 15 myfile.dat

HELP
   exit 1
}

cleanup() {
   $RM_BIN "$ERROR_FILE"
   $RM_BIN "$SUM_FILE"
   $RM_BIN "$BIN_FILE"
}

ROOT_PATH=`root_path`
APP=`basename $0`

ECHO_BIN='/bin/echo'
RM_BIN='/bin/rm -rf'
DD_BIN='/bin/dd'
MD5_BIN='/usr/bin/md5sum'
CUT_BIN='/usr/bin/cut'
GREP_BIN='/bin/grep'
CAT_BIN='/bin/cat'
AWK_BIN='/usr/bin/awk'
XXD_BIN='/usr/bin/xxd'

# Check parameters
if [ $# -ne 2 ]; then help_show; fi
if [ "$1" == "-h" -o "$1" == "--help" ]; then help_show; fi

FILE="$2"

if [ ! -f "$FILE" ]; then
   $ECHO_BIN "ERROR : File '$FILE' not found"
   exit 2
fi

M=4
SIZE=`echo "$1 * $M" | bc | sed -r 's,\.0+,,'`
BS=`echo "1024 / $M" | bc | sed -r 's,\.0+,,'`
BS="${BS}k"

if ! is_integer "$SIZE"; then
   $ECHO_BIN "ERROR : Chunk size is not an integer number ($1 * $M = $SIZE)"
   exit 2
fi

ERROR_FILE='/tmp/s3md5-error-$$.out'
SUM_FILE='/tmp/s3md5-md5sumlist-$$.out'
BIN_FILE='/tmp/s3md5-md5bin-$$.out'

trap "{ cleanup; }" EXIT

$ECHO_BIN -n > "$SUM_FILE"
$ECHO_BIN -n > "$BIN_FILE"

n=0
i=0

while true; do
   if [ $DEBUG -eq 1 ]; then
      part=$((n+1))
      to=$((i+SIZE))
      $ECHO_BIN -n "SUM for part $part ($i to $to x $BS) ... "
   fi
   sum=`$DD_BIN bs=$BS count=$SIZE skip=$i if="$FILE" 2> "$ERROR_FILE" | $MD5_BIN | $CUT_BIN -d' ' -f1`

   if $GREP_BIN -q "cannot skip" "$ERROR_FILE"; then
      # End of file, break this loop
      if [ $DEBUG -eq 1 ]; then
         $ECHO_BIN "END"
      fi
      break
   elif [ $sum == 'd41d8cd98f00b204e9800998ecf8427e' ]; then
      # MD5 of an empty string, break this loop
      if [ $DEBUG -eq 1 ]; then
         $ECHO_BIN "END ($sum, empty string)"
      fi
      break
   else
      # Chunk read
      if [ $DEBUG -eq 1 ]; then
         $ECHO_BIN "OK - $sum"
      fi
      i=$((i+SIZE))
      n=$((n+1))
      # Add its md5 sum to sum list file
      $ECHO_BIN "$sum" >> "$SUM_FILE"
   fi
done

if [ $DEBUG -eq 1 ]; then
   $ECHO_BIN "Converting all md5sums to binary"
fi

# Convert all md5 sums (in hex text notation) to bin and concatenate them into a file
$CAT_BIN "$SUM_FILE" | $AWK_BIN '{print $1}' | while read MD5; do echo $MD5 | $XXD_BIN -r -p >> "$BIN_FILE"; done

# Calculate MD5 sum of this binary file
s3sum=`$MD5_BIN "$BIN_FILE" | $CUT_BIN -d' ' -f1`
if [ $DEBUG -eq 1 ]; then
   $ECHO_BIN -n "Etag/S3 MD5 Sum : "
fi

# Return Etag/S3 MD5 Sum
$ECHO_BIN "$2/$1		$s3sum-$n"
