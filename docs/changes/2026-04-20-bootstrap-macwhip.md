# 2026-04-20 bootstrap-macwhip

## 배경

대상 저장소가 비어 있었기 때문에, MacWhip MVP를 greenfield로 부트스트랩해야 했습니다.

## 목표

- Swift 네이티브 메뉴바 앱 골격 구축
- OpenWhip 핵심 동작 계약 구현
- `miyeonSlap-pet` 감지 로직 직접 재사용

## 변경 내용

- SwiftPM executable package 생성
- `MacWhipCore` 내부 모듈 및 `MacWhipTests` 테스트 타깃 추가
- 메뉴바 popover, HUD, recent events window 추가
- IOKit 기반 물리 감지 adapter 추가
- `CGEvent` 기반 keyboard macro sender 추가
- self-check 기반 자동 검증 / CI workflow 추가
- README / AGENTS / architecture docs 추가

## 설계 이유

- Empty repo였기 때문에 초기 구조부터 테스트와 문서를 함께 맞추는 편이 유지보수에 유리했습니다.
- 물리 감지 helper process보다 in-process Swift 재사용이 더 단순하고 검증 가능했습니다.

## 영향 범위

- 저장소 전체 초기 구조

## 검증 방법

- `swift build`
- `swift test`
- `swift run MacWhip --self-check`
- 수동 메뉴바 실행 및 슬랩 테스트 검증

## 남아 있는 한계

- signed app bundle 및 release artifact 부재
- 물리 센서 미지원 하드웨어 fallback 제한

## 후속 과제

- app bundle packaging
- notarization/signing
- supported terminal bundle ID 보완
