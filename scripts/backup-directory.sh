#!/usr/bin/env bash
# Create one compressed archive of a directory in a separate destination.
set -euo pipefail
umask 077

if (( $# != 2 )); then
    printf 'Usage: %s SOURCE_DIRECTORY ARCHIVE_DIRECTORY\n' "${0##*/}" >&2
    exit 64
fi

if [[ ! -d $1 || ! -d $2 ]]; then
    printf 'Both arguments must be existing directories.\n' >&2
    exit 64
fi

source_dir=$(cd -- "$1" && pwd -P)
archive_dir=$(cd -- "$2" && pwd -P)

if [[ $source_dir == / || $archive_dir == "$source_dir" || $archive_dir == "$source_dir/"* ]]; then
    printf 'The archive directory must be outside the source directory.\n' >&2
    exit 64
fi

source_name=${source_dir##*/}
source_parent=${source_dir%/*}
[[ -n $source_parent ]] || source_parent=/

archive=$(mktemp "$archive_dir/backup-$(date +%Y%m%d-%H%M%S).XXXXXXXX.tar.gz")
trap 'rm -f -- "$archive"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

tar -czf "$archive" -C "$source_parent" -- "$source_name"
tar -tzf "$archive" > /dev/null

trap - EXIT
printf '%s\n' "$archive"
