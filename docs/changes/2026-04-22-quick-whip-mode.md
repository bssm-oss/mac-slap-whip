# 2026-04-22 quick-whip-mode

## 배경

기존 메뉴바 UI가 대상/모드/프롬프트 설정 중심이라, 실제로는 "맥북을 툭 치면 바로 재촉"이라는 핵심 사용 흐름이 너무 복잡했습니다.

## 목표

- 탭 한 번으로 바로 동작하는 고정형 quick whip 모드 제공
- 재촉 문구를 `"더 빨리!!"`로 고정
- 트리거 시 채찍 HUD가 더 분명하게 보이도록 개선

## 변경 내용

- 기본 동작을 `활성 터미널 + Ctrl+C + "더 빨리!!" + Enter`로 고정
- 프리셋/사용자 지정 프롬프트 UI 제거
- 메뉴바 popover를 quick whip 중심의 단순한 카드 UI로 재구성
- HUD를 채찍 스트라이크 애니메이션 중심의 어두운 오버레이로 교체
- 물리 slap 감지를 `slap-mac-replica` 방식의 root helper 기반 감지로 교체
- self-check 및 phrase 테스트를 새 기본 문구 기준으로 갱신
- README 사용 방법을 단순 모드 기준으로 업데이트

## 설계 이유

- 실제 사용 시 자주 바뀌지 않는 옵션을 빼야 탭 제스처와 결과 사이의 연결이 분명해집니다.
- `Ctrl+C`는 유지해야 실행 중인 에이전트 세션에서도 재촉 문구가 바로 먹히는 경우가 많습니다.
- HUD는 단순 성공 토스트보다 물리 탭의 피드백을 강하게 주는 편이 목적에 맞습니다.

## 영향 범위

- `Sources/MacWhip/App/`
- `Sources/MacWhip/Detection/`
- `Sources/MacWhip/Support/`
- `Helpers/MacWhipSlapHelper/`
- `Tests/MacWhipTests/`
- `README.md`

## 검증 방법

- `swift build`
- `swift test`
- `swift run MacWhip --self-check`
- `cd Helpers/MacWhipSlapHelper && go test ./...`
- `zsh scripts/package_release_zip.sh`
- `codesign --verify --deep --strict dist/MacWhip.app`
- `dist/MacWhip.app/Contents/Resources/MacWhipSlapHelper` 포함 확인
- `ioreg -l -w0` 에서 `AppleSPUHIDDevice` 확인
- helper 비root 실행 시 `accelerometer access requires root` 실패 확인

## 남아 있는 한계

- 물리 센서 인식 가능 여부는 여전히 하드웨어별 편차가 있습니다.
- 물리 slap 감지 시작 시 관리자 승인이 필요합니다.
- 실제 물리 slap end-to-end 검증은 관리자 승인 프롬프트 이후에만 가능합니다.
