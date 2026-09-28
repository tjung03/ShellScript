#!/usr/bin/env bash
# 디렉터리 하나를 별도 보관 경로에 gzip 압축 아카이브로 생성한다.
# 오류가 누락되지 않도록 엄격 모드를 사용하고, 새 파일은 호출자만 접근하게 한다.
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

# 상대 경로와 심볼릭 링크를 실제 경로로 정규화하여 경로 포함 관계를 정확히 비교한다.
source_dir=$(cd -- "$1" && pwd -P)
archive_dir=$(cd -- "$2" && pwd -P)

# 루트 전체 백업과 원본 내부로의 출력은 범위 확대·재귀 포함 위험이 있어 거부한다.
if [[ $source_dir == / || $archive_dir == "$source_dir" || $archive_dir == "$source_dir/"* ]]; then
    printf 'The archive directory must be outside the source directory.\n' >&2
    exit 64
fi

source_name=${source_dir##*/}
source_parent=${source_dir%/*}
[[ -n $source_parent ]] || source_parent=/

# 예측하기 어려운 고유 이름을 만들고, 성공하기 전까지는 종료 시 결과물을 제거한다.
archive=$(mktemp "$archive_dir/backup-$(date +%Y%m%d-%H%M%S).XXXXXXXX.tar.gz")
trap 'rm -f -- "$archive"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# 원본의 상위 경로에서 실행해 아카이브에 절대 경로 대신 디렉터리 이름부터 기록한다.
tar -czf "$archive" -C "$source_parent" -- "$source_name"
# 생성 직후 목록을 읽어 최소한 압축 형식이 다시 열리는지 확인한다.
tar -tzf "$archive" > /dev/null

# 검증까지 성공한 파일만 보존한다.
trap - EXIT
printf '%s\n' "$archive"
