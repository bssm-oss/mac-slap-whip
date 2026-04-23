# MacWhip

![MacWhip Logo](Branding/MacWhipLogo.svg)

MacWhip은 OpenWhip의 핵심 아이디어를 **Swift 네이티브 macOS 메뉴바 앱**으로 다시 만든 프로젝트입니다. 마우스로 채찍을 휘두르는 대신, **MacBook을 가볍게 탭하거나 노크했을 때** 현재 포커스된 AI 코딩 에이전트 터미널 세션으로 `Ctrl+C`와 짧은 재촉 문구를 보내도록 설계했습니다.

이 프로젝트는 **Claude 전용 앱이 아닙니다.** Claude Code, Codex CLI, OpenCode CLI, 그리고 일반적인 터미널 기반 AI 에이전트 세션을 동일한 방식으로 다룹니다. 핵심 동작은 서비스 API 연동이 아니라 **포커스된 터미널에 키보드 인터럽트/문구를 주입하는 것**입니다.

## 주의 사항

- 이 앱은 MacBook을 **세게 치라고 만든 앱이 아닙니다.**
- 목적은 **가벼운 탭 / 노크 감지**입니다.
- 기기 손상을 유도하지 마세요.
- 모델별 센서 접근 가능 여부와 감지 정확도는 다를 수 있습니다.

## 핵심 기능

- macOS 메뉴바 앱
- Start Listening / Stop Listening
- 탭 감지 시 현재 포커스된 터미널에 `Ctrl+C` 후 `"더 빨리!!"` 전송
- 채찍 스트라이크 HUD 오버레이 표시
- `slap-mac-replica` 방식의 root helper 기반 물리 slap 감지
- Sensitivity / Cooldown 조절
- Test Slap Event 버튼
- 손쉬운 사용 권한 상태 표시 및 설정 열기
- 최근 50개 이벤트 로그 보기

## 기술 스택

- Swift 6
- Swift Package Manager
- AppKit
- SwiftUI
- Go helper + `github.com/taigrr/apple-silicon-accelerometer`
- IOKit HID (`AppleSPUHIDDevice`) 기반 물리 탭/충격 감지(root helper)
- CoreGraphics `CGEvent` 기반 키보드 매크로 전송

## 요구 환경

- macOS 13 이상
- Xcode Command Line Tools 또는 Swift 6 toolchain
- 가능하면 Apple Silicon MacBook
- 손쉬운 사용(Accessibility) 권한
- 물리 slap 감지를 시작할 때 관리자 승인 필요

## 빠른 설치 / 실행

### 1) 가장 쉬운 설치: Releases에서 내려받기

GitHub Releases에서 `MacWhip.zip`을 내려받아 압축을 풀고 `MacWhip.app`을 실행하세요.

```bash
xattr -dr com.apple.quarantine MacWhip.app
open MacWhip.app
```

> notarization/signing 전까지는 Gatekeeper 경고가 발생할 수 있습니다.

### 2) 저장소 클론

```bash
git clone https://github.com/bssm-oss/mac-slap-whip.git
cd mac-slap-whip
```

### 3) 빌드

```bash
swift build
```

### 4) 실행

```bash
swift run MacWhip
```

실행하면 메뉴바에 MacWhip 로고 아이콘이 나타납니다.

## 테스트 실행 방법

```bash
swift test
swift run MacWhip --self-check
cd Helpers/MacWhipSlapHelper && go test ./...
```

## 릴리스 아티팩트 만들기

```bash
zsh scripts/build_release_app.sh
zsh scripts/package_release_zip.sh
```

생성 결과:

- `dist/MacWhip.app`
- `dist/MacWhip.zip`

## 브랜딩 자산

- `Branding/MacWhipLogo.svg`: GitHub/문서용 로고
- `Branding/AppIcon.icns`: macOS 앱 아이콘
- `Sources/MacWhip/Resources/MenuBarIconTemplate.png`: 메뉴바 템플릿 아이콘

## 손쉬운 사용 권한 설정

키보드 매크로를 전송하려면 macOS 손쉬운 사용 권한이 필요합니다.

1. 앱 실행
2. 메뉴바 popover에서 `권한 확인` 또는 `설정 열기` 클릭
3. macOS 설정에서 MacWhip 또는 현재 실행 중인 터미널/개발 환경에 필요한 권한 허용

권한이 없으면 앱은 조용히 실패하지 않고, 상태와 HUD에 이유를 표시합니다.

## 사용 방법

1. 터미널에서 Claude Code / Codex / OpenCode 등을 실행합니다.
2. 메뉴바에서 MacWhip을 열고 `감지 시작`을 누릅니다.
3. macOS가 관리자 승인을 요청하면 승인합니다. 이 승인은 `slap-mac-replica`와 같은 방식으로 숨겨진 가속도계 센서를 root helper가 읽기 위해 필요합니다.
4. 필요하면 민감도와 쿨다운만 가볍게 조절합니다.
5. MacBook을 가볍게 탭/노크하거나, `채찍 테스트` 버튼으로 동작을 검증합니다.

물리 slap 감지 동작은 아래 순서입니다.

1. `감지 시작` 클릭
2. 앱이 번들된 `MacWhipSlapHelper`를 관리자 권한으로 실행
3. helper가 `AppleSPUHIDDevice` 가속도계를 `slap-mac-replica` 방식으로 읽음
4. helper가 slap 이벤트를 런타임 로그 파일에 기록
5. 앱이 slap 이벤트를 읽고 쿨다운 확인
6. 손쉬운 사용 권한 확인
7. 현재 포커스 앱이 터미널인지 확인
8. 필요 시 이전 외부 앱으로 복귀
9. `Ctrl+C` 전송
10. `"더 빨리!!"` 입력
11. `Enter` 전송
12. 채찍 HUD 오버레이 표시

`채찍 테스트` 버튼은 물리 센서와 관리자 helper를 거치지 않고 5번 이후의 키보드 매크로/HUD 경로만 검증합니다.

## 권한 모델

MacWhip에는 서로 다른 두 권한이 필요합니다.

- 손쉬운 사용 권한: 현재 포커스된 터미널에 `Ctrl+C`, `"더 빨리!!"`, `Enter`를 보내기 위해 필요합니다.
- 관리자 승인: 숨겨진 `AppleSPUHIDDevice` 가속도계를 읽는 root helper를 시작하기 위해 필요합니다.

관리자 승인은 GUI 앱 전체를 root로 실행하지 않습니다. 앱은 일반 사용자 권한으로 실행되고, 물리 센서 읽기만 `MacWhipSlapHelper`가 담당합니다.

## 폴더 구조

```text
Sources/MacWhipApp/
Sources/MacWhip/
  App/
  Automation/
  Detection/
  Domain/
  Support/

Helpers/MacWhipSlapHelper/
Tests/MacWhipTests/
docs/
```

## 아키텍처 개요

- `App/AppState.swift`: 메뉴바 상태, 감지 시작/중지, 트리거 파이프라인, HUD/로그 연결
- `Detection/SlapMacReplicaEventSource.swift`: 관리자 권한 helper 실행, helper 이벤트 로그 polling, slap 이벤트 변환
- `Detection/SlapHelperEventParser.swift`: helper 로그의 `slap amplitude=...` 라인을 앱 이벤트로 변환
- `Detection/SPUSensorProbe.swift`: `ioreg` 기반 `AppleSPUHIDDevice` 존재 여부 표시
- `Automation/AgentCommandDispatcher.swift`: 타깃 앱 검증 후 `Ctrl+C → 문구 → Enter` 실행
- `Automation/KeyboardMacroSender.swift`: `CGEvent` 기반 키보드 이벤트 주입
- `Helpers/MacWhipSlapHelper`: `slap-mac-replica` 방식의 root 센서 helper
- `App/MenuBarController.swift`: `NSStatusItem + NSPopover` 셸
- `App/HUDWindowController.swift`: 비활성 HUD 패널
- `MacWhipCore`: 내부 재사용 모듈

## 개발 원칙

- OpenWhip의 핵심 동작 계약을 유지하되, MacWhip에 맞는 간단한 채찍 HUD는 재구현
- 물리 감지는 `slap-mac-replica`와 동일하게 root helper에서 수행
- 권한 부족과 비지원 하드웨어를 명확히 드러냄
- 민감한 터미널 내용은 저장하지 않음

## CI 개요

GitHub Actions에서 다음을 실행합니다.

- `swift build`
- `swift test`
- `swift run MacWhip --self-check`
- `cd Helpers/MacWhipSlapHelper && go test ./...`
- `zsh scripts/package_release_zip.sh`

## 검증 체크리스트

- `swift build` 통과
- `swift test` 통과
- `swift run MacWhip --self-check` 통과
- `cd Helpers/MacWhipSlapHelper && go test ./...` 통과
- `zsh scripts/package_release_zip.sh` 통과
- `codesign --verify --deep --strict dist/MacWhip.app` 통과
- `dist/MacWhip.app/Contents/Resources/MacWhipSlapHelper` 실행 파일 포함 확인
- `ioreg -l -w0`에서 `AppleSPUHIDDevice` 확인
- root가 아닌 helper 실행이 `accelerometer access requires root`로 실패하는지 확인
- 실제 물리 slap end-to-end 검증은 관리자 승인 후 `감지 시작`으로 수행

## 알려진 제한 사항

- 포커스된 터미널이 아니면 기본 설정에서는 동작하지 않습니다.
- 일부 Mac 모델에서는 `AppleSPUHIDDevice` 가속도 센서 접근이 불가능할 수 있습니다.
- 센서 접근 방식과 하드웨어 차이로 감지 정확도가 달라질 수 있습니다.
- 물리 센서 접근은 `slap-mac-replica`와 동일하게 root helper가 담당합니다. GUI 앱 전체를 root로 실행하지는 않습니다.
- 현재 앱은 물리 탭 감지가 지원되지 않는 경우 자동 물리 fallback을 제공하지 않으며, 대신 `채찍 테스트`로 전체 매크로 경로를 검증할 수 있습니다.

## 향후 개선 가능 항목

- detector availability를 더 세밀하게 표시
- supported terminal bundle ID 확장
- notarization/signing 적용

## 기여 방법

1. 기능 브랜치 생성
2. `swift build`, `swift test`, `swift run MacWhip --self-check` 실행
3. 수동 검증 결과와 함께 PR 생성
