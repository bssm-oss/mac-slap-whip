# OpenWhip 분석 요약

## 확인한 파일

- `README.md`
- `package.json`
- `main.js`
- `preload.js`
- `overlay.html`

## 핵심 결론

OpenWhip의 본질은 whip 애니메이션이 아니라 아래 동작 계약입니다.

1. 트리거 발생
2. 대상 앱 포커스 복귀
3. `Ctrl+C` 전송
4. 짧은 문구 입력
5. `Enter` 전송

`overlay.html`은 whip 물리/사운드/애니메이션 중심의 UX 계층이고, 실제 매크로 로직은 `main.js`에 있습니다.

## MacWhip에 반영한 부분

- whip 그래픽은 재현하지 않음
- 메뉴바 + HUD만 유지
- 핵심 매크로 계약만 계승
