# Shell Script

Linux에서 Bash로 디렉터리를 압축 백업하고, 기준 파일과 현재 파일의 내용 변화를 점검하는 작은 실습 저장소입니다. 제공된 셸 학습노트와 강의 자료의 주제를 바탕으로 **새로 작성한 예제**이며, 과거 실습의 원본 스크립트나 운영 이력을 재현한 것은 아닙니다.

| 예제 | 입력 → 결과 | 다루는 개념 |
| --- | --- | --- |
| [`scripts/backup-directory.sh`](scripts/backup-directory.sh) | 원본 디렉터리 + 별도 보관 디렉터리 → 압축 아카이브 | 인자 검사, 경로 처리, 임시 파일, 실패 시 정리, `tar` |
| [`scripts/check-file-changes.sh`](scripts/check-file-changes.sh) | 기준 파일 + 현재 파일 → 동일/변경/오류 상태 | 조건문, 종료 코드, 파일 내용 비교 |

## 빠른 실행

Linux의 Bash, GNU tar, GNU coreutils(`mktemp`), GNU diffutils(`cmp`)가 필요합니다. 아래 명령은 저장소 루트에서 실행합니다.

```bash
mkdir -p demo/source demo/archives
printf 'hello\n' > demo/source/sample.txt
cp -- demo/source/sample.txt demo/baseline.txt

bash scripts/check-file-changes.sh demo/baseline.txt demo/source/sample.txt
bash scripts/backup-directory.sh demo/source demo/archives
```

백업 스크립트는 새 아카이브 경로를 출력합니다. `tar -tzf "출력된-아카이브-경로"`로 목록을 확인할 수 있습니다. 변경 점검은 두 파일의 **내용**이 같으면 0, 다르면 1, 읽기 실패 등 오류에는 2를 반환합니다. 사용법 오류는 64를 반환합니다. 예시 파일을 바꾼 뒤 다시 점검하면 변경 상태를 확인할 수 있습니다.

## 동작 범위

- 백업 대상은 기존 디렉터리이며 보관 디렉터리도 미리 있어야 합니다. 보관 디렉터리를 백업 대상 내부로 지정하면 중복 포함을 막기 위해 거부합니다. 심볼릭 링크로 디렉터리를 지정하면 실제 경로를 사용하며, 아카이브에는 실제 대상 디렉터리 이름부터 기록됩니다.
- 백업 실패 시 생성 중이던 아카이브를 삭제하고, 성공한 아카이브는 남깁니다. 압축 직후 아카이브 목록을 읽어 형식을 확인하지만, 별도 복구 시험이나 실행 중 변경되는 파일의 일관성까지 보장하지는 않습니다.
- 변경 점검은 지정한 **한 쌍의 일반 파일** 내용만 비교합니다. 파일을 가리키는 심볼릭 링크를 지정하면 연결 대상의 내용을 비교합니다. 자동 기준본 생성, 파일 메타데이터 점검, 주기 실행, 알림 전송은 포함하지 않습니다.
- 민감한 데이터는 입력하지 마세요. 백업 아카이브는 호출자에게만 읽기 권한이 부여되도록 생성되지만, 보관 장소와 복원 절차는 사용하는 환경에서 별도로 관리해야 합니다.

## 현재 사용 방식과 참고

학습 자료의 고정된 서버 주소·비밀번호, Telnet/FTP 원격 자동화, 무분별한 삭제 명령은 여기서 사용하지 않습니다. 예제는 인자를 따옴표로 묶고, 임시 아카이브 이름을 `mktemp`로 만들며, `cmp`의 종료 상태를 구분합니다. 이전 자료의 환경 설정을 그대로 실행할 필요 없이 자신의 테스트 디렉터리에서 시작할 수 있습니다.

- [GNU Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [GNU tar Manual](https://www.gnu.org/software/tar/manual/tar.html)
- [GNU coreutils: mktemp](https://www.gnu.org/software/coreutils/manual/html_node/mktemp-invocation.html)
- [GNU diffutils: cmp](https://www.gnu.org/software/diffutils/manual/html_node/Invoking-cmp.html)
