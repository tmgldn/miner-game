#!/bin/bash

echo "do nothing"
exit 0

DIR="$0"
DIR="$(dirname $DIR)"
for file in $DIR/*.psd; do magick "$file" -background none -alpha on -flatten "${file%.*}.png"; done
