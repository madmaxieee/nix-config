#!/usr/bin/env bash

: "${WM_IDS_DB_PATH:=${XDG_STATE_HOME:-$HOME/.local/state}/aerospace/wm-state.db}"

wm_ids_require_sqlite3() {
	command -v sqlite3 >/dev/null 2>&1 || {
		echo "error: sqlite3 not found" >&2
		return 1
	}
}

wm_ids_sql_escape() {
	printf '%s' "$1" | sed "s/'/''/g"
}

__wm_ids_initialized=0

wm_ids_init() {
	if [[ "$__wm_ids_initialized" -eq 1 ]]; then
		return 0
	fi

	wm_ids_require_sqlite3 || return 1

	mkdir -p "$(dirname "$WM_IDS_DB_PATH")" || return 1

	sqlite3 "$WM_IDS_DB_PATH" <<-'SQL'
		PRAGMA journal_mode = WAL;

		CREATE TABLE IF NOT EXISTS ids (
			id TEXT PRIMARY KEY,
			updated_at INTEGER NOT NULL DEFAULT (unixepoch())
		);

		CREATE TABLE IF NOT EXISTS metadata (
			key TEXT PRIMARY KEY,
			value INTEGER NOT NULL
		);
	SQL

	__wm_ids_initialized=1
}

wm_ids_add() {
	local id

	wm_ids_init || return 1
	id="$(wm_ids_sql_escape "$1")"

	sqlite3 "$WM_IDS_DB_PATH" <<-SQL
		INSERT INTO ids (id)
		VALUES ('$id')
		ON CONFLICT(id) DO UPDATE
		SET updated_at = unixepoch();
	SQL
}

wm_ids_remove() {
	local id

	wm_ids_init || return 1
	id="$(wm_ids_sql_escape "$1")"

	sqlite3 "$WM_IDS_DB_PATH" <<-SQL
		DELETE FROM ids
		WHERE id = '$id';
	SQL
}

wm_ids_has() {
	local id

	wm_ids_init || return 1
	id="$(wm_ids_sql_escape "$1")"

	sqlite3 -noheader "$WM_IDS_DB_PATH" <<-SQL
		SELECT EXISTS(
		  SELECT 1
		  FROM ids
		  WHERE id = '$id'
		);
	SQL
}

wm_ids_contains() {
	local result

	result="$(wm_ids_has "$1")" || return 1
	[[ "$result" == "1" ]]
}

wm_ids_list() {
	wm_ids_init || return 1

	sqlite3 -noheader "$WM_IDS_DB_PATH" <<-'SQL'
		SELECT id
		FROM ids
		ORDER BY id;
	SQL
}

wm_ids_count() {
	wm_ids_init || return 1

	sqlite3 -noheader "$WM_IDS_DB_PATH" <<-'SQL'
		SELECT COUNT(*)
		FROM ids;
	SQL
}

wm_ids_clear() {
	wm_ids_init || return 1

	sqlite3 "$WM_IDS_DB_PATH" <<-'SQL'
		DELETE FROM ids;
	SQL
}

wm_ids_should_cleanup() {
	local last_cleanup
	local current_time

	wm_ids_init || return 1

	last_cleanup=$(sqlite3 -noheader "$WM_IDS_DB_PATH" "SELECT value FROM metadata WHERE key = 'last_cleanup';" 2>/dev/null)
	[[ -z "$last_cleanup" ]] && last_cleanup=0

	current_time=$(date +%s)

	((current_time - last_cleanup > 3600))
}

wm_ids_record_cleanup() {
	local current_time

	wm_ids_init || return 1
	current_time=$(date +%s)

	sqlite3 "$WM_IDS_DB_PATH" <<-SQL
		INSERT INTO metadata (key, value)
		VALUES ('last_cleanup', $current_time)
		ON CONFLICT(key) DO UPDATE
		SET value = $current_time;
	SQL
}

wm_ids_touch() {
	wm_ids_init
}

wm_ids_touch >/dev/null
