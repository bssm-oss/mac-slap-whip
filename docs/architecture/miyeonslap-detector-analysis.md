# miyeonSlap-pet 감지 로직 분석 요약

## 확인한 파일

- `Package.swift`
- `README.md`
- `Sources/MiyeonSlap/PhysicalSlapDetector.swift`
- `Sources/LovaSlapPET/PhysicalSlapDetector.swift`

## 결론

- 저장소는 Swift 6 / SwiftPM / AppKit 기반입니다.
- 감지 로직은 `AppleSPUHIDDevice` accelerometer report를 읽는 in-process Swift 구현입니다.
- 원본 구현 핵심 값:
  - threshold: `0.12`
  - decimation: `2`
  - baseline smoothing: `0.08`
  - warmup sample: `24`
  - quiet period: `0.22s`
- 원본 구현은 `onHit` closure만 제공했습니다.

## MacWhip에 반영한 부분

- direct Swift integration
- `SlapEventSource` + `SlapEvent` 형태의 adapter
- sensitivity / cooldown / baseline calibration 노출
- GUI 앱 전체를 root로 실행하지 않음
