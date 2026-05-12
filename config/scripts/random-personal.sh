#!/usr/bin/env bash
WALL_DIR="$HOME/Bangers_Walls"
CACHE_FILE="/tmp/personal-shuffle-list"

# get current wallpapers on disk
DISK_LIST=$(find "$WALL_DIR" -maxdepth 1 -type f \
	\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \) \
	! -name ".*")

# if cache missing or empty, build fresh
if [ ! -s "$CACHE_FILE" ]; then
	echo "$DISK_LIST" | shuf > "$CACHE_FILE"
else
	# find new images not yet in cache
	NEW_IMAGES=$(echo "$DISK_LIST" | grep -vxFf "$CACHE_FILE")

	# insert new images at random positions — fixed: no subshell loop
	if [ -n "$NEW_IMAGES" ]; then
		TMP=$(mktemp)
		cp "$CACHE_FILE" "$TMP"

		while IFS= read -r img; do
			LINES=$(wc -l < "$TMP")
			INSERT_AT=$(( (RANDOM % (LINES + 1)) + 1 ))
			# use temp file properly outside subshell
			TMP2=$(mktemp)
			awk -v line="$INSERT_AT" -v val="$img" \
				'NR==line{print val} {print}' "$TMP" > "$TMP2"
			mv "$TMP2" "$TMP"
		done <<< "$NEW_IMAGES"

		mv "$TMP" "$CACHE_FILE"
	fi
fi

# pick next wallpaper, skip deleted files
selected_path=""
while IFS= read -r line; do
	if [ -f "$line" ]; then
		selected_path="$line"
		grep -vxF "$line" "$CACHE_FILE" > "${CACHE_FILE}.tmp"
		mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
		break
	fi
done < "$CACHE_FILE"

# apply
if [ -n "$selected_path" ]; then
	qs ipc call randomwallpaper apply "$selected_path"
fi
