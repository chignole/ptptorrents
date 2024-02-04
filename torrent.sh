#!/bin/bash

# set -euo pipefail
# IFS=$'\n\t'

# TODO Check aria2c dependencies
# TODO Check arguments - If no arguments use options directory
# TODO Add torrents source folder
# TODO Check tracker
# TODO Add consume mode
# TODO Make script usable from any directory
# TODO Add a choice for a custom symlink input
#
# Usage : ./torrent.sh {foo.torrent} - if no argument specified, the script
#         will scan source folder for torrents and process them.

# Options
#   source : Source directory with torrents you want to process
#   movies : Directory containing the movies you want to use for symlinks

source="./"
movies="/mnt/medias.2/Movies"

# Code

if [[ ! -e $movies ]]; then
	echo "[ERRO] Movies directory doesn't exist."
	exit 0
fi

# Process torrent file specified in argument - If no arguments process every file
# in source folder
if [[ -n $1 ]]; then
	torrentlist=("$1")
else
	readarray -d '' torrentlist < <(find $source -iname "*.torrent" -print0)
fi
current=1
total=${#torrentlist[@]}

# Process every torrent in the torrentlist array
for torrent in "${torrentlist[@]}"; do
	unset folder

	filename=$(aria2c -S "$torrent" | grep "[0-9]" | grep "|" | grep "mkv" | grep -vi "sample" | sed 's/.*\/\(.*mkv\)/\1/g')

	pathname=$(aria2c -S "$torrent" | grep "[0-9]" | grep "|" | grep "mkv" | grep -vi "sample")

	# Check for subfolders
	if [[ "$pathname" =~ /.*/ ]]; then
		echo "[$current/$total] [INFO] Subfolder detected"
		folder=$(echo "$pathname" | sed 's/.*\/\(.*\)\/.*mkv/\1/g')
		mkdir -p "$folder"
	fi

	echo "[$current/$total] [INFO] $filename"

	find=$(find $movies -iwholename "$filename")

	if [[ -n $find ]]; then
		echo "[$current/$total] [INFO] Found $find"
		movie="$find"
		if [[ -n "$folder" ]]; then
			ln -s "$movie" "$folder/$filename"
		else
			ln -s "$movie" "$filename"
		fi
	else
		echo "[$current/$total] [INFO] No match found found for $filename"
		shortname=$(echo "$filename" | sed 's/\(.\{5\}\).*/\1/g')
		readarray -d '' array < <(find $movies -iname "$shortname*.mkv" -print0)

		if [[ ${#array[@]} == 0 ]]; then
			shortname=$(echo "$filename" | sed 's/\(.\{2\}\).*/\1/g')
			readarray -d '' array < <(find $movies -iname "$shortname*.mkv" -print0)
			echo "[$current/$total] [ERRO] No match found for $filename"
			echo "[$current/$total] [INFO] File path : "
			read -e movie
			if [[ -n "$folder" ]]; then
				ln -s "$movie" "$folder/$filename"
			else
				ln -s "$movie" "$filename"
			fi
		fi

		if [[ ${#array[@]} == 1 ]]; then
			echo "[$current/$total]" Found "${array[0]}"
			movie="${array[0]}"
			if [[ -n "$folder" ]]; then
				ln -s "$movie" "$folder/$filename"
			else
				ln -s "$movie" "$filename"
			fi
		fi

		if [[ ${#array[@]} -gt 1 ]]; then
			array+=('Custom path')
			select movie in "${array[@]}"; do
				echo "[$current/$total] [INFO] You have chosen $movie"
				if [[ "$REPLY" != "${#array[@]}" ]]; then
					if [[ -n "$folder" ]]; then
						ln -s "$movie" "$folder/$filename"
					else
						ln -s "$movie" "$filename"
					fi
				else
					echo "[$current/$total] [INFO] File path : "
					read -e movie
					if [[ -n "$folder" ]]; then
						ln -s "$movie" "$folder/$filename"
					else
						ln -s "$movie" "$filename"
					fi
				fi
				break
			done
		fi
	fi
	current=$((current + 1))
done
