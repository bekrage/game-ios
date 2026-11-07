# 개인 Mac 없이 iOS 빌드
개발/테스트 기준: Godot 4.6.3. iPhone 15 Pro 대상 arm64, iOS 16 이상, 가로 화면.
1280×720 canvas_items 종횡비 유지: iPhone 15 Pro 2556×1179 화면에서는 좌우 여백으로
노치/다이내믹 아일랜드와 조작 영역 사이 공간을 확보합니다. 실기기 안전 영역은 추가 확인 필요합니다.

## GitHub Actions
1. 이 프로젝트 폴더의 내용(project.godot과 .github 포함)을 GitHub 저장소 **루트**에 올립니다.
2. Actions → Godot iOS Cloud Build → Run workflow.
3. Apple Team ID와 고유 bundle ID를 입력합니다. 서명 없는 컴파일 확인만 할 때는 기본값 사용 가능.
4. macos-15 클라우드 러너가 Godot 4.6.3과 같은 버전의 공식 iOS 템플릿을 내려받고,
   테스트 → Xcode 프로젝트 내보내기 → ARM64 서명 없는 xcarchive 생성을 수행합니다.
5. 실행 결과의 BubbleDino-iOS-unsigned 아티팩트를 내려받습니다.
   클라우드 서비스 요금/사용 가능 시간은 계정에 따릅니다.

2026-11-07 GitHub macos-15에서 실제 실행하여 게임 테스트 53개, Xcode 내보내기,
서명 없는 arm64 xcarchive 생성이 통과했습니다. Apple 서명과 실기기 실행은 미검증입니다.
실행: https://github.com/bekrage/game-ios/actions/runs/42345555646
Godot 버전을 바꿀 때 workflow의 GODOT_VERSION과 로컬 엔진/템플릿을 함께 맞춥니다.

## 설치 가능한 IPA / TestFlight
서명 없는 xcarchive나 ZIP을 아이폰에 직접 설치할 수는 없습니다.
Apple Developer Program 계정과 해당 bundle ID의 배포 인증서/프로비저닝 프로파일이 필요합니다.
Codemagic 등 macOS CI의 보안 파일/비밀 변수 저장소에 인증서(.p12), 암호, 프로파일을 등록하세요.
저장소나 채팅에 인증서를 넣지 마세요.

위 워크플로의 Xcode 내보내기까지 동일하게 수행한 뒤, 사용하는 CI의 Apple 코드 서명 통합으로:
- 임시 keychain에 배포 인증서와 개인 키를 가져옵니다.
- 프로파일을 ~/Library/MobileDevice/Provisioning Profiles 에 설치합니다.
- export_presets.cfg의 application/app_store_team_id와 bundle_identifier를 계정에 맞춥니다.
- unsigned archive 단계를 수동 서명 archive 단계로 교체합니다:
  xcodebuild -project <생성된.xcodeproj> -scheme BubbleDino -configuration Release
  -destination 'generic/platform=iOS' -archivePath build/BubbleDino.xcarchive
  DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="Apple Distribution" PROVISIONING_PROFILE_SPECIFIER="<프로파일 이름>" archive
- xcodebuild -exportArchive -archivePath build/BubbleDino.xcarchive
  -exportPath build/signed -exportOptionsPlist ExportOptions.plist
  를 실행합니다. ExportOptions.plist는 method=app-store-connect, teamID,
  signingStyle=manual, provisioningProfiles={bundle ID:프로파일 이름}로 준비합니다.
- 생성된 IPA를 CI의 App Store Connect API 통합으로 TestFlight에 업로드합니다.
  등록된 기기 Ad Hoc 설치라면 method=release-testing과 Ad Hoc 프로파일을 사용합니다.

서명 자동화는 사용자 계정/인증서가 제공되지 않아 포함된 unsigned 워크플로와 별도입니다.
TestFlight에서 실제 iPhone 15 Pro로 동시 터치, 홈 이동 후 복귀, 오디오, 10스테이지,
발열/프레임률을 검증한 뒤 배포하세요.
