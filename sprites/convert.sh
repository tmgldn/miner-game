#!/bin/bash
for file in *.psd; do magick "$file" -background none -alpha on -flatten "${file%.*}.png"; done
