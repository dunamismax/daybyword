# Day by Word: one command for each job. `make help` lists the targets.
# `make check` is the gate before every commit, and `make check-full` runs at
# each milestone and before every TestFlight build or deploy (AGENTS.md §7).

SHELL := /bin/sh
.DEFAULT_GOAL := help

CATALOG := build/catalog/Catalog.sqlite
APP_CATALOG := apple/App/Resources/Catalog.sqlite
PACKAGES := ReadingEngine ReadingData CatalogCompiler
SWIFT_SOURCES := Packages/*/Sources Packages/*/Tests Packages/*/Package.swift \
	Server/Sources Server/Tests Server/Package.swift apple
PORT ?= 8080

.PHONY: help tokens generate catalog build test-packages test-server test-app test-ui \
	test-linux run serve screenshot lint format strings check-strings tour tour-app tour-web check check-full archive testflight deploy clean

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  %-14s %s\n", $$1, $$2 }'

tokens: ## Regenerate the color assets, DesignTokens.swift, and tokens.css from design/tokens.json
	@swift scripts/tokens.swift generate

generate: catalog ## Generate apple/DayByWord.xcodeproj from apple/project.yml
	@cd apple && xcodegen generate --quiet

catalog: ## Compile the catalog for the server and the app bundle (RELEASE=1 for release mode)
	@swift run --package-path Packages/CatalogCompiler --quiet catalog build \
		--output $(CATALOG) $(if $(RELEASE),--release)
	@cp $(CATALOG) $(APP_CATALOG)

build: generate ## Build the app for the simulator
	@scripts/xcodebuild.sh build-simulator -destination "$$(scripts/sim-destination.sh)" build

test-packages: ## Test the shared packages on macOS
	@for package in $(PACKAGES); do \
		echo "== $$package"; \
		swift test --package-path Packages/$$package --quiet || exit 1; \
	done

test-server: ## Test the server on macOS
	@echo "== Server"
	@swift test --package-path Server --quiet

test-app: generate ## Run the app's unit tests in the simulator
	@scripts/xcodebuild.sh test-app -destination "$$(scripts/sim-destination.sh)" -only-testing:AppTests test

test-ui: generate ## Run the app's UI tests in the simulator
	@scripts/xcodebuild.sh test-ui -destination "$$(scripts/sim-destination.sh)" -only-testing:AppUITests test

test-linux: ## Test the packages and the server on Linux, in a container
	@scripts/test-linux.sh

run: generate ## Build, boot, install, and launch the app in the simulator
	@scripts/run-app.sh

serve: catalog ## Serve the site on http://localhost:8080 with the development catalog (PORT=…)
	@DBW_PORT=$(PORT) DBW_PUBLIC_DIR=Server/Public DBW_CATALOG=$(CATALOG) \
		swift run --package-path Server --quiet DayByWordServer

screenshot: ## Save a screenshot of the booted simulator in screenshots/
	@mkdir -p screenshots
	@xcrun simctl io booted screenshot "screenshots/$$(date +%Y%m%d-%H%M%S).png"

lint: ## Check the toolchain, formatting, imports, design tokens, and raw colors
	@scripts/check-toolchain.sh
	@swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)
	@scripts/check-imports.sh
	@swift scripts/tokens.swift check
	@scripts/check-colors.sh

format: ## Format the Swift sources in place
	@swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)

strings: build ## Add the app's new interface strings to its String Catalog and drop stale ones
	@swift scripts/strings.swift sync

check-strings: ## Check the String Catalog against the last build's strings (after test-app)
	@swift scripts/strings.swift check

tour: tour-app tour-web ## Visit every section in light and dark in the app and on the web, saving screenshots

tour-app: generate ## Tour the app in the simulator; screenshots go to screenshots/app/
	@mkdir -p screenshots/app
	@TEST_RUNNER_DBW_SCREENSHOTS="$(CURDIR)/screenshots/app" scripts/xcodebuild.sh tour-app \
		-destination "$$(scripts/sim-destination.sh)" -only-testing:AppUITests/TourTests test

tour-web: catalog ## Tour the site in a real browser through WebDriver; screenshots go to screenshots/web/
	@swift build --package-path Server --quiet
	@swift scripts/webtour.swift

check: lint catalog test-packages test-server test-app check-strings ## The gate before every commit
	@echo "check: all passed"

check-full: check tour-web tour-app test-linux ## The milestone gate: check, both tours in light and dark, and Linux
	@echo "check-full: all passed"

archive: ## Build a signed Release archive for TestFlight (docs/release.md)
	@scripts/archive.sh

testflight: ## Upload build/DayByWord.xcarchive to App Store Connect (docs/release.md)
	@scripts/testflight.sh

deploy: ## Deploy origin/main to daybyword.com
	@echo "deploy: not built yet (BUILD.md P7.2)" >&2; exit 1

clean: ## Remove build products and the generated Xcode project
	rm -rf build Packages/*/.build Server/.build apple/DayByWord.xcodeproj
