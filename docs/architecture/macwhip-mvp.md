# MacWhip MVP Architecture

## 배경

MacWhip은 OpenWhip의 핵심 상호작용을 Electron 없이 macOS Swift 네이티브 앱으로 옮긴 프로젝트입니다.

## 핵심 결정

- OpenWhip의 핵심 동작만 유지: `trigger -> target validation -> Ctrl+C -> optional phrase -> Enter`
- whip 애니메이션은 재구현하지 않음
- 감지 로직은 `miyeonSlap-pet`의 Swift/IOKit 구현을 직접 재사용
- 메뉴바 앱 셸은 AppKit, 내용 뷰는 SwiftUI

## 구성 요소

- `AppState`: 앱 상태와 트리거 파이프라인
- `MiyeonSlapPetAdapter`: 물리 탭 이벤트 소스
- `AgentCommandDispatcher`: 포커스 앱 검증과 실제 키 입력 동작
- `KeyboardMacroSender`: `CGEvent` 전송
- `MenuBarController`: `NSStatusItem + NSPopover`
- `HUDWindowController`: non-activating HUD

## Target Agent 의미

- `Target Agent`는 transport 자체를 바꾸지 않습니다.
- 대신 선택한 대상에 맞춰 **기본 프롬프트 프리셋**과 **권장 Action Mode**를 바꿉니다.
- 모든 대상은 결국 포커스된 터미널 세션에 키보드 매크로를 주입하는 같은 경로를 사용합니다.

## 감지 파이프라인

1. `MiyeonSlapPetAdapter`가 `AppleSPUHIDDevice` accelerometer report를 수신
2. baseline calibration 이후 impulse 계산
3. sensitivity / cooldown 조건 충족 시 `SlapEvent` 발생
4. `AppState`가 이벤트를 받아 `AgentCommandDispatcher` 호출
5. 결과는 HUD + recent event log로 반영

## 현재 한계

- 감지 하드웨어가 없는 Mac에서는 물리 감지가 불가능함
- release ZIP은 제공하지만 notarization/signing은 아직 없음
