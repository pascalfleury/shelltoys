#!/bin/bash 

. $(dirname $0)/revdir.shlib

rev_setup /tmp/revdir-$$

echo "File 1" > /tmp/file1.txt
rev_open /tmp/file1.txt F1FILE
cat /tmp/file1.txt > $F1FILE
rev_close $F1FILE
echo "$F1FILE"

sleep 2

rev_open /tmp/file1.txt F2FILE TOKEN
cat /tmp/file1.txt > $F2FILE
rev_close $F2FILE force
echo "$F2FILE -- $TOKEN"

sleep 2

rev_open /tmp/file1.txt F3FILE
cat /tmp/file1.txt > $F3FILE
cat /tmp/file1.txt >> $F3FILE
rev_close $F3FILE
echo "$F3FILE"

ls -lR /tmp/revdir-$$
rm -rf /tmp/revdir-$$
