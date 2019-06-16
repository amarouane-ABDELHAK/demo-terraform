#! /bin/bash
for var in "$@"
do
    sed -e "s/\\(.*=\\)\\(.*\\)/\\1[Redacted]/" $var > $var.example
done