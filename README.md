# MacWhip

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
- Target Agent: Active Terminal / Claude Code / Codex / OpenCode / Custom
- Action Mode: Interrupt only / Interrupt + Prompt / Prompt only
- Sensitivity / Cooldown 조절
- Test Slap Event 버튼
- 손쉬운 사용 권한 상태 표시 및 설정 열기
- 최근 50개 이벤트 로그 보기
- 짧은 HUD 오버레이 표시
- `miyeonSlap-pet`의 Swift 기반 물리 감지 로직을 직접 재사용한 in-process detector

## 기술 스택

- Swift 6
- Swift Package Manager
- AppKit
- SwiftUI
- IOKit HID (`AppleSPUHIDDevice`) 기반 물리 탭/충격 감지
- CoreGraphics `CGEvent` 기반 키보드 매크로 전송

## 요구 환경

- macOS 13 이상
- Xcode Command Line Tools 또는 Swift 6 toolchain
- 가능하면 Apple Silicon MacBook
- 손쉬운 사용(Accessibility) 권한

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

실행하면 메뉴바에 `🥁` 아이콘이 나타납니다.

## 테스트 실행 방법

```bash
swift test
swift run MacWhip --self-check
```

## 릴리스 아티팩트 만들기

```bash
zsh scripts/build_release_app.sh
zsh scripts/package_release_zip.sh
```

생성 결과:

- `dist/MacWhip.app`
- `dist/MacWhip.zip`

## 손쉬운 사용 권한 설정

키보드 매크로를 전송하려면 macOS 손쉬운 사용 권한이 필요합니다.

1. 앱 실행
2. 메뉴바 popover에서 `권한 확인` 또는 `설정 열기` 클릭
3. macOS 설정에서 MacWhip 또는 현재 실행 중인 터미널/개발 환경에 필요한 권한 허용

권한이 없으면 앱은 조용히 실패하지 않고, 상태와 HUD에 이유를 표시합니다.

## 사용 방법

1. 터미널에서 Claude Code / Codex / OpenCode 등을 실행합니다.
2. 메뉴바에서 MacWhip을 열고 다음을 설정합니다.
   - 대상 에이전트
   - 동작 모드
   - 민감도
   - 쿨다운
   - 프롬프트 프리셋 또는 사용자 지정 문구
3. `감지 시작`을 누릅니다.
4. MacBook을 가볍게 탭/노크하거나, `슬랩 테스트` 버튼으로 동작을 검증합니다.

기본 동작은 아래 순서입니다.

1. 탭 이벤트 감지
2. 쿨다운 확인
3. 손쉬운 사용 권한 확인
4. 현재 포커스 앱 확인
5. 필요 시 이전 외부 앱으로 복귀
6. `Ctrl+C` 전송
7. 짧은 문구 입력
8. `Enter` 전송

## 폴더 구조

```text
Sources/MacWhipApp/
Sources/MacWhip/
  App/
  Automation/
  Detection/
  Domain/
  Support/

Tests/MacWhipTests/
docs/
```

## 아키텍처 개요

- `App/AppState.swift`: 메뉴바 상태, 감지 시작/중지, 트리거 파이프라인, HUD/로그 연결
- `Detection/MiyeonSlapPetAdapter.swift`: `miyeonSlap-pet` 감지 로직을 직접 포팅한 물리 이벤트 소스
- `Automation/AgentCommandDispatcher.swift`: 타깃 앱 검증 후 `Ctrl+C → 문구 → Enter` 실행
- `Automation/KeyboardMacroSender.swift`: `CGEvent` 기반 키보드 이벤트 주입
- `App/MenuBarController.swift`: `NSStatusItem + NSPopover` 셸
- `App/HUDWindowController.swift`: 비활성 HUD 패널
- `MacWhipCore`: 내부 재사용 모듈

## 개발 원칙

- OpenWhip의 핵심 동작 계약만 유지하고, whip UI는 재구현하지 않음
- 물리 감지는 별도 helper보다 in-process Swift 재사용을 우선
- 권한 부족과 비지원 하드웨어를 명확히 드러냄
- 민감한 터미널 내용은 저장하지 않음

## CI 개요

GitHub Actions에서 다음을 실행합니다.

- `swift build`
- `swift test`
- `swift run MacWhip --self-check`

## 알려진 제한 사항

- 포커스된 터미널이 아니면 기본 설정에서는 동작하지 않습니다.
- `Allow any focused app`를 켜면 터미널 제한은 해제되지만, 잘못된 앱에 입력이 들어갈 수 있습니다.
- 일부 Mac 모델에서는 `AppleSPUHIDDevice` 가속도 센서 접근이 불가능할 수 있습니다.
- 센서 접근 방식과 하드웨어 차이로 감지 정확도가 달라질 수 있습니다.
- 하드웨어/OS 조합에 따라 sensor access를 위해 별도 helper 또는 권한 분리가 필요할 수 있습니다. 현재 MVP는 GUI 앱 전체를 root로 실행하지 않습니다.
- 현재 앱은 물리 탭 감지가 지원되지 않는 경우 자동 물리 fallback을 제공하지 않으며, 대신 `슬랩 테스트`로 전체 매크로 경로를 검증할 수 있습니다.

## 향후 개선 가능 항목

- detector availability를 더 세밀하게 표시
- supported terminal bundle ID 확장
- signed app bundle 및 릴리스 아티팩트 제공
- notarization/signing 적용

## 기여 방법

1. 기능 브랜치 생성
2. `swift build`, `swift test`, `swift run MacWhip --self-check` 실행
3. 수동 검증 결과와 함께 PR 생성
