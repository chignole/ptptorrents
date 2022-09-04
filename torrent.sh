#!/bin/bash

# set -euo pipefail
# IFS=$'\n\t'

# TODO Check aria2c dependencies
# TODO Check arguments - If no arguments use options directory
# TODO Check if mkv file is in subfolder, and create it if needed

# options #
###########

source="./"
movies="/mnt/medias.2/Movies"

# code    #
###########

if [[ ! -e $movies ]]; then
  echo "[ERRO] Movies directory doesn't exist." 
  exit 0
fi

# readarray -d '' torrentlist < <(find $source -iname "*.torrent" -print0)
torrentlist=("$1")
total=${#torrentlist[@]}
current=1

for torrent in "${torrentlist[@]}"
do
  folder="empty"

  filename=$(aria2c -S "$torrent" | grep "[0-9]" | grep "|"  | grep "mkv" | grep -vi "sample" | sed 's/.*\/\(.*mkv\)/\1/g')  

# folder=$(aria2c -S "$torrent" | grep "[0-9]" | grep "|" | grep "mkv" | grep -vi "sample" | sed 's/.*\/\(.*\)\/.*.mkv/\1/g')

  echo "FOLDER : $folder"

  if [[ $folder != "empty" ]]; then
    mkdir "$folder"
  fi

echo "[$current/$total] [INFO] $filename"

find=$(find $movies -iwholename "$filename")

if [[ -n $find ]]; then
	echo "[$current/$total] [INFO] Found $find"
	ln -s "$find" "$filename"
else
	echo "[$current/$total] [INFO] No match found found for $filename"
	shortname=$(echo "$filename" | sed 's/\(.\{5\}\).*/\1/g')
  # echo "$shortname"
	readarray -d '' array < <(find $movies -iname "$shortname*.mkv" -print0)
  if [[ ${#array[@]} == 0 ]]; then
    echo "[$current/$total] [ERRO] No match found for $filename"
  fi

  if [[ ${#array[@]} == 1 ]]; then
    echo "[$current/$total]" Found "${array[0]}"
    ln -s "${array[0]}" "$filename"
  fi

  if [[ ${#array[@]} -gt 1 ]]; then
		select movie in "${array[@]}"
		do
		  echo "[INFO] You have chosen $movie"
		  ln -s "$movie" "$filename"
		break 
		done
	fi
fi
current=$((current+1))
done
