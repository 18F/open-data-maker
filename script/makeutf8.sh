#!/bin/sh
# convert to utf8 and strip Byte Order Mark (BOM) if present
mkdir -p utf8

for file in *.csv; do
    echo "$file"
    iconv -f ascii -t utf-8 "$file" | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' > "./utf8/${file%.txt}"
done
