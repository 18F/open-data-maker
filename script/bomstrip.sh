#!/bin/sh
mkdir -p new

for filename in ./*.csv; do
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' "$filename" > new/$filename
done

#find . -print0 -type f |  awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' {} > new/{}
