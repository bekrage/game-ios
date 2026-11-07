# 분석 및 테스트 결과
검사일: 2026-11-07 / Linux / Godot 4.6.3.stable.official.7d41c59c4

## 기존 프로젝트 분석
단일 Main.tscn과 main.gd가 모든 게임 로직/그리기/PCM 소리 합성을 담당했습니다.
기본 이동, 바닥 점프, 포획/처치, 단계 증가, 단순 멜로디와 터치가 이미 있었습니다.
10단계는 적 숫자/속도 증가만 있고 발판이 없었습니다.
키보드와 터치를 같은 상태에 덮어쓰며, 앱 전환/일시정지 처리가 없었습니다.

## 수정 사항
- 기존 게임 로직을 유지하면서 10가지 발판 배치/색상/스테이지 이름 추가.
- 발판 위 착지/점프, 발판별 적 순찰, 후반 적 수/속도 증가.
- 키보드와 다중 터치 입력 병합, 독립 손가락 해제, 포커스 손실 시 입력 해제.
- 일시정지/재개와 전체 음소거, 스테이지 시작 보호와 제목 표시.
- 가로 방향 및 종횡비 유지 설정 명시.
- 오디오 종료 시 재생 중단/리소스 해제로 종료 시 ObjectDB 누수 경고 해결.
- iOS arm64 export preset, GitHub macOS CI, 서명/설치 안내 추가.
- 공식 Godot 4.6 Apple exporter 소스와 대조: project-only 내보내기는
  지정 경로 옆에 .xcodeproj를 직접 생성하므로 CI에서 이를 찾아 컴파일합니다.

## 수행한 검사
1. Godot headless editor import: GDScript 파싱 오류 수정 후 게임 실행에서 파싱 오류 없음.
   제한된 샌드박스에서 에디터 디버그 서버 listen 소켓 생성 경고가 발생했습니다.
   초기 기본 HOME 쓰기 오류는 XDG 데이터/설정/캐시 경로를 /tmp로 지정해 해결했습니다.
2. 자동 게임플레이: **53/53 통과**, 종료 코드 0.
   각 10단계의 적 수/발판/120프레임 시뮬레이션, 키보드 이동, 점프, 발판 착지,
   포획, 제한 시간 후 탈출, 처치 점수, 일시정지,
   두 손가락 이동+발사/개별 해제, 포커스 손실,
   게임 오버/재시작, 1~10단계 클리어 전환과 최종 승리.
   단계 전환 검사는 적 목록을 비워 클리어 상태를 주입하는 방식이며,
   사람이 모든 적을 처치하는 전체 플레이 검사는 아닙니다.
3. 메인 씬 기본 실행: headless 600 physics frames, 종료 코드 0,
   스크립트/런타임 오류 및 누수 경고 없음. 배경 합성음 생성 코드도 실행됨.
4. ZIP 무결성 검사 통과.

재현:
XDG_DATA_HOME=/tmp/godot-data XDG_CONFIG_HOME=/tmp/godot-config XDG_CACHE_HOME=/tmp/godot-cache \
godot --headless --path . --script res://tests/gameplay.gd

## 검증 범위와 남은 확인
렌더링 화면/사람의 실제 플레이, 청음, iPhone 15 Pro 실기기, FPS/발열,
macOS CI 실행, Xcode archive, Apple 서명과 TestFlight는 수행하지 않았습니다.
입력 검사는 합성 InputEvent를 사용했으며 실제 iOS 터치 드라이버 검증은 아닙니다.
Linux에는 macOS SDK와 Apple 인증서가 없으므로 설치 가능한 IPA를 만들었다고 주장하지 않습니다.
클라우드 빌드 설정은 준비되었으며 사용자 GitHub/Apple 계정에서 실행해야 합니다.
