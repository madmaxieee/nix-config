#!/usr/bin/env bash

# Source the helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/wm-id-helper.sh"

cleanup() {
	local active_ids
	local db_ids
	local id

	# Get all active window IDs from aerospace
	active_ids=$(aerospace list-windows --all --format '%{window-id}' 2>/dev/null)

	# Get all tracked window IDs from the database
	db_ids=$(wm_ids_list)

	# If no IDs are tracked, there is nothing to clean up
	[[ -z "$db_ids" ]] && return 0

	# Iterate over the tracked IDs
	while IFS= read -r id; do
		[[ -z "$id" ]] && continue

		# If the tracked ID is not in the list of active IDs, remove it
		if ! echo "$active_ids" | grep -Fqx "$id"; then
			wm_ids_remove "$id"
		fi
	done <<<"$db_ids"
}

if wm_ids_should_cleanup; then
	cleanup
	wm_ids_record_cleanup
fi
