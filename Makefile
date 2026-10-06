.PHONY: apk web install

APK ?= build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

apk:
	flutter build apk --split-per-abi
web:
	flutter build web
install:
	adb install -r $(APK)
