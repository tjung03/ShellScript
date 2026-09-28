#!/usr/bin/env bash
# 기준 파일과 현재 파일의 바이트 내용을 비교한다.
# 종료 코드: 0=동일, 1=변경, 2=비교 오류, 64=사용법 오류
set -uo pipefail

if (( $# != 2 )); then
    printf 'Usage: %s BASELINE_FILE CURRENT_FILE\n' "${0##*/}" >&2
    exit 64
fi

# 디렉터리나 읽을 수 없는 입력을 cmp에 넘기기 전에 명시적인 오류로 처리한다.
for file in "$@"; do
    if [[ ! -f $file || ! -r $file ]]; then
        printf 'An input is not a readable regular file.\n' >&2
        exit 2
    fi
done

# cmp의 1은 실행 실패가 아니라 '내용이 다름'이므로 별도 상태로 보존한다.
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
