#!/bin/bash
# script to shuffle lines in a file and number them
# USe case: to shuffle exam questions, students, etc.

# File to read
filename="students.txt"

# Check if file exists
if [[ ! -f $filename ]]; then
  echo "File not found!"
  exit 1
fi

# Shuffle lines, number them, and print
shuf "$filename" | nl -w1 -s". "
