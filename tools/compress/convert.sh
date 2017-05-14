#! /bin/bash

head -c 4K $1 > $2
tail -c 4K $1 > $3
./filediff $2 $2
./filediff $3 $3
./rle -e $2
./rle -e $3
