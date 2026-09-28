#!/usr/bin/env bash
# 두 예제의 공개 동작 계약을 격리된 임시 디렉터리에서 확인한다.
set -uo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
backup_script="$repo_root/scripts/backup-directory.sh"
check_script="$repo_root/scripts/check-file-changes.sh"
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

checks=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

pass() {
    checks=$((checks + 1))
    printf 'PASS: %s\n' "$1"
}

expect_status() {
    local expected=$1
    local label=$2
    shift 2

    "$@" > /dev/null 2>&1
    local actual=$?
    if (( actual != expected )); then
        fail "$label (expected=$expected, actual=$actual)"
    fi
    pass "$label"
}

# 저장소의 세 스크립트가 Bash 문법 검사를 통과하는지 먼저 확인한다.
bash -n "$backup_script" "$check_script" "${BASH_SOURCE[0]}" || fail 'Bash syntax'
pass 'Bash syntax'

source_dir="$work_dir/source directory"
archive_dir="$work_dir/archives"
mkdir -p -- "$source_dir" "$archive_dir"
printf 'before\n' > "$source_dir/sample.txt"
cp -- "$source_dir/sample.txt" "$work_dir/baseline.txt"

# 파일 비교의 네 가지 공개 종료 상태를 각각 확인한다.
expect_status 0 'matching files return 0' \
    bash "$check_script" "$work_dir/baseline.txt" "$source_dir/sample.txt"
printf 'after\n' > "$source_dir/sample.txt"
expect_status 1 'changed files return 1' \
    bash "$check_script" "$work_dir/baseline.txt" "$source_dir/sample.txt"
expect_status 2 'missing input returns 2' \
    bash "$check_script" "$work_dir/baseline.txt" "$work_dir/missing.txt"
expect_status 64 'invalid comparison usage returns 64' \
    bash "$check_script"
ln -s -- "$source_dir/sample.txt" "$work_dir/current-link.txt"
expect_status 1 'file symlink follows its target' \
    bash "$check_script" "$work_dir/baseline.txt" "$work_dir/current-link.txt"

# 성공한 백업은 경로·권한·내용이 계약과 일치해야 한다.
archive=$(bash "$backup_script" "$source_dir" "$archive_dir") || fail 'archive creation'
[[ -f $archive ]] || fail 'archive path exists'
[[ $(stat -c '%a' -- "$archive") == 600 ]] || fail 'archive permission is 600'
[[ $(tar -xOzf "$archive" 'source directory/sample.txt') == after ]] \
    || fail 'archive preserves file content'
pass 'archive creation, permission, and content'

# 디렉터리 심볼릭 링크를 입력해도 실제 대상 이름을 기준으로 백업한다.
ln -s -- "$source_dir" "$work_dir/source-link"
linked_archive=$(bash "$backup_script" "$work_dir/source-link" "$archive_dir") \
    || fail 'directory symlink backup'
[[ $(tar -xOzf "$linked_archive" 'source directory/sample.txt') == after ]] \
    || fail 'directory symlink resolves to its target'
pass 'directory symlink resolves to its target'

# 출력 경로가 원본 내부이면 백업 파일이 다시 포함될 수 있으므로 거부해야 한다.
mkdir -- "$source_dir/nested-output"
expect_status 64 'nested archive directory is rejected' \
    bash "$backup_script" "$source_dir" "$source_dir/nested-output"

# tar 실패를 주입해 EXIT trap이 생성 중인 임시 아카이브를 제거하는지 확인한다.
fake_bin="$work_dir/fake-bin"
failed_archive_dir="$work_dir/failed-archives"
mkdir -- "$fake_bin" "$failed_archive_dir"
printf '#!/usr/bin/env bash\nexit 9\n' > "$fake_bin/tar"
chmod 755 "$fake_bin/tar"
expect_status 9 'tar failure is propagated' \
    env PATH="$fake_bin:$PATH" bash "$backup_script" "$source_dir" "$failed_archive_dir"
shopt -s nullglob
leftovers=("$failed_archive_dir"/*)
(( ${#leftovers[@]} == 0 )) || fail 'partial archive cleanup'
pass 'partial archive cleanup'

printf 'All checks passed. (%d checks)\n' "$checks"
