#!/usr/bin/env bash
# Compare the byte content of one baseline file and one current file.
set -uo pipefail

if (( $# != 2 )); then
    printf 'Usage: %s BASELINE_FILE CURRENT_FILE\n' "${0##*/}" >&2
    exit 64
fi

for file in "$@"; do
    if [[ ! -f $file || ! -r $file ]]; then
        printf 'An input is not a readable regular file.\n' >&2
        exit 2
    fi
done

if cmp -s -- "$1" "$2"; then
    printf '[OK] File contents match.\n'
    exit 0
else
    result=$?
    if (( result == 1 )); then
        printf '[CHANGED] File contents differ.\n'
        exit 1
    fi
    printf 'File comparison failed.\n' >&2
    exit 2
fi
