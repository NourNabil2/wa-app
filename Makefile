# ============================================================
#  FastWay Mobile — Flutter Dev Makefile
# ============================================================

.PHONY: help web web-local web-main web-aws ios android clean build-web build-main build-aws dev dev-hot

GREEN  := \033[0;32m
YELLOW := \033[1;33m
CYAN   := \033[0;36m
RESET  := \033[0m

## help: Print available commands
help:
	@echo ""
	@echo "$(CYAN)FastWay Mobile — Available Commands$(RESET)"
	@echo "────────────────────────────────────────────────────"
	@grep -E '^## ' Makefile | sed 's/## /  $(GREEN)/' | sed 's/:/$(RESET)\t/'
	@echo ""

## web: Run Flutter web (main branch API — fastway.atwdemo.com)
web:
	flutter run -d chrome

## web-local: Run Flutter web against local Laravel (localhost:8000)
web-local:
	@echo "$(GREEN)→ API: http://localhost:8000$(RESET)"
	flutter run -d chrome \
		--dart-define=USE_LOCAL=true

## web-main: Run Flutter web against Main branch API (fastway.atwdemo.com)
web-main:
	@echo "$(GREEN)→ API: https://fastway.atwdemo.com$(RESET)"
	flutter run -d chrome \
		--dart-define=BASE_URL=https://fastway.atwdemo.com/api/v1

## web-aws: Run Flutter web against AWS branch API (admin.fastwayprotein.com)
web-aws:
	@echo "$(GREEN)→ API: https://admin.fastwayprotein.com$(RESET)"
	flutter run -d chrome \
		--dart-define=BASE_URL=https://admin.fastwayprotein.com/api/v1

## dev: ⚡ FAST — Build web (profile) + serve on :5557 (LOW CPU/RAM)
dev:
	@echo "$(YELLOW)⚡ Building web (profile mode)…$(RESET)"
	flutter build web \
		--profile \
		--dart-define=USE_LOCAL=true
	@echo "$(GREEN)✓ Build done. Serving on http://localhost:5557$(RESET)"
	@echo "$(YELLOW)  Press Ctrl+C to stop. Re-run 'make dev' after code changes.$(RESET)"
	cd build/web && python3 -m http.server 5557

## dev-hot: 🔥 Hot reload but lighter (no DevTools)
dev-hot:
	@echo "$(GREEN)→ API: http://localhost:8000 (no DevTools — low memory)$(RESET)"
	flutter run -d chrome \
		--dart-define=USE_LOCAL=true \
		--web-port=5557

## ios: Run on iOS simulator
ios:
	flutter run -d iPhone

## android: Run on Android emulator
android:
	flutter run -d android

## clean: Clean build artifacts
clean:
	flutter clean
	flutter pub get

## build-web: Build for web production (Main branch — fastway.atwdemo.com)
build-web:
	flutter build web --dart-define=BASE_URL=https://fastway.atwdemo.com/api/v1 --release

## build-main: Build production for Main branch (fastway.atwdemo.com)
build-main:
	@echo "$(CYAN)Building for Main → https://fastway.atwdemo.com$(RESET)"
	flutter build web \
		--release \
		--pwa-strategy=none \
		--dart-define=USE_LOCAL=false \
		--dart-define=BASE_URL=https://fastway.atwdemo.com/api/v1

## build-aws: Build production for AWS branch (admin.fastwayprotein.com)
build-aws:
	@echo "$(CYAN)Building for AWS → https://admin.fastwayprotein.com$(RESET)"
	flutter build web \
		--release \
		--pwa-strategy=none \
		--dart-define=USE_LOCAL=false \
		--dart-define=BASE_URL=https://admin.fastwayprotein.com/api/v1
