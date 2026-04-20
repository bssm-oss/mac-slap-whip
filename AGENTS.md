# AGENTS.md

## 프로젝트 목적

MacWhip은 MacBook의 가벼운 탭/노크 이벤트를 감지해, 현재 포커스된 AI 에이전트 터미널 세션에 `Ctrl+C` 및 짧은 프롬프트를 보내는 macOS 메뉴바 앱입니다.

## 빠른 시작 명령

```bash
swift build
swift test
swift run MacWhip
swift run MacWhip --self-check
```

## 설치 / 실행 / 테스트 명령

- 빌드: `swift build`
- 자동 테스트: `swift test`
- 앱 실행: `swift run MacWhip`
- 셀프 체크: `swift run MacWhip --self-check`

## 기본 작업 순서

1. `README.md`, `AGENTS.md`, `docs/` 확인
2. 현재 브랜치와 `git status` 확인
3. 최소 변경 설계 선택
4. 코드 수정
5. 테스트/셀프체크 실행
6. 수동 검증 수행
7. 문서 갱신
8. 브랜치/커밋/PR 정리

## 완료 조건

- 요청 기능이 실제 코드에 반영됨
- `swift build` 통과
- `swift test` 통과
- `swift run MacWhip --self-check` 통과
- 핵심 수동 검증 수행
- README / docs / AGENTS 최신 상태 유지

## 코드 스타일 원칙

- AppKit 셸 + SwiftUI 내용 뷰 구조 유지
- 감지, 자동화, UI 상태를 분리
- 테스트 가능한 로직은 프로토콜 경계 뒤로 이동
- 타입 안전성 훼손 금지

## 파일 구조 원칙

- `Sources/MacWhip/App/` - 앱 셸, 메뉴바, HUD, 상태
- `Sources/MacWhip/Detection/` - 물리 센서 감지
- `Sources/MacWhip/Automation/` - 타깃 앱 검증, 키보드 매크로
- `Sources/MacWhip/Domain/` - enum / model
- `Sources/MacWhip/Support/` - 프레이즈, 로그 등

## 문서화 원칙

- 구조 변화는 `docs/architecture/` 반영
- 사용자 실행 방법 변화는 `README.md` 반영
- 작업 단위 변화는 `docs/changes/` 반영

## 테스트 원칙

- 순수 로직은 `swift test`로 검증
- 앱 실행 전 최소 `--self-check` 유지
- 자동화 권한/센서 하드웨어가 필요한 동작은 수동 검증 결과를 문서/PR에 남김

## 브랜치 / 커밋 / PR 규칙

- 기본 브랜치 직접 작업 금지
- 브랜치 예시: `feat/bootstrap-macwhip`
- 커밋은 구현 / 테스트 / 문서 단위로 분리
- PR에는 자동 검증 + 수동 검증 + 남은 한계 포함

## 민감한 경로 / 수정 주의 경로

- `Detection/MiyeonSlapPetAdapter.swift` - private-ish IOKit 센서 접근 로직
- `Automation/KeyboardMacroSender.swift` - 실제 키보드 이벤트 주입
- `Automation/AgentCommandDispatcher.swift` - 잘못 수정하면 오입력 가능

## 작업 전 체크리스트

- 대상 브랜치 확인
- `git status` 확인
- README/AGENTS/docs 읽기
- 요청 범위 재확인

## 작업 후 체크리스트

- `swift build`
- `swift test`
- `swift run MacWhip --self-check`
- 수동 검증 수행
- 문서 업데이트 확인

## 절대 하면 안 되는 것

- 테스트 없이 완료 선언
- 손쉬운 사용 권한 부족을 숨긴 채 동작한다고 주장
- 물리 센서 미지원 상태를 숨기기
- 터미널이 아닌 앱에 무심코 입력 보내도록 기본값 변경
