# Local Runbook

## 기본 실행

```bash
swift build
swift run MacWhip
```

## 기본 검증

```bash
swift test
swift run MacWhip --self-check
```

## 릴리스 패키징

```bash
zsh scripts/build_release_app.sh
zsh scripts/package_release_zip.sh
```

## 수동 검증 포인트

1. 메뉴바 아이콘 표시
2. 권한 상태 표시
3. 슬랩 테스트 버튼으로 `Ctrl+C -> 문구 -> Enter` 경로 검증
4. 최근 이벤트 창 표시
5. HUD 자동 사라짐 확인
