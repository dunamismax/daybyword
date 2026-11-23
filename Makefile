# Day by Word: one command for each job. `make help` lists the targets.
# `make check` is the gate before every commit, and `make check-full` runs at
# each milestone and before every TestFlight build or deploy (AGENTS.md §7).

SHELL := /bin/sh
.DEFAULT_GOAL := help

CATALOG := build/catalog/Catalog.sqlite
APP_CATALOG := apple/App/Resources/Catalog.sqlite
PACKAGES := ReadingEngine ReadingData CatalogCompiler
SWIFT_SOURCES := Packages/*/Sources Packages/*/Tests Packages/*/Package.swift apple
PORT ?= 8080
WEB_STAMP := web/node_modules/.modules.yaml

# SvelteKit, Vite, and Tailwind send no telemetry; nothing to switch off
# (AGENTS.md §5, decision E36).

.PHONY: help tokens generate catalog check-catalog build test-packages test-app test-ui \
	test-linux run screenshot lint format \
	web-install lint-web types-web test-web build-web smoke-web serve-web check-web test-domain-browser audit-web \
	catalog-export check-export rights-audit db-generate db-drift test-db strings check-strings tour tour-app tour-web app-store-screenshots check check-full check-signing archive testflight deploy clean

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  %-14s %s\n", $$1, $$2 }'

tokens: ## Regenerate the color assets, DesignTokens.swift, and tokens.css from design/tokens.json
	@swift scripts/tokens.swift generate

generate: catalog ## Generate apple/DayByWord.xcodeproj from apple/project.yml
	@cd apple && xcodegen generate --quiet

catalog: ## Compile the catalog for the app bundle (RELEASE=1 for release mode)
	@swift run --package-path Packages/CatalogCompiler --quiet catalog build \
		--output $(CATALOG) $(if $(RELEASE),--release)
	@cp $(CATALOG) $(APP_CATALOG)

check-catalog: ## Check our own plans' schedules against their rules, the rights audit (docs/rights-audit.md), and compile the catalog in release mode too, which refuses plans with uncleared sources
	@swift scripts/plans.swift check
	@swift scripts/rights-audit.swift check
	@swift run --package-path Packages/CatalogCompiler --quiet catalog build \
		--output build/catalog/Catalog-release.sqlite --release

build: generate ## Build the app for the simulator
	@scripts/xcodebuild.sh build-simulator -destination "$$(scripts/sim-destination.sh)" build

test-packages: ## Test the shared packages on macOS
	@for package in $(PACKAGES); do \
		echo "== $$package"; \
		swift test --package-path Packages/$$package --quiet || exit 1; \
	done

test-app: generate ## Run the app's unit tests in the simulator
	@scripts/xcodebuild.sh test-app -destination "$$(scripts/sim-destination.sh)" -only-testing:AppTests test

test-ui: generate ## Run the app's UI tests in the simulator
	@scripts/xcodebuild.sh test-ui -destination "$$(scripts/sim-destination.sh)" -only-testing:AppUITests test

app-store-screenshots: generate ## Make the App Store's screenshots on the 6.9-inch iPhone and 13-inch iPad, light and dark; they go to screenshots/app-store/
	@scripts/app-store-screenshots.sh

rights-audit: ## Write docs/rights-audit.md from catalog/SOURCES.md and the plans (P18.1)
	@swift scripts/rights-audit.swift generate

test-linux: ## Test the Swift packages on Linux, in a container
	@scripts/test-linux.sh

run: generate ## Build, boot, install, and launch the app in the simulator
	@scripts/run-app.sh

screenshot: ## Save a screenshot of the booted simulator in screenshots/
	@mkdir -p screenshots
	@xcrun simctl io booted screenshot "screenshots/$$(date +%Y%m%d-%H%M%S).png"

lint: ## Check the toolchain, formatting, imports, design tokens, and raw colors
	@scripts/check-toolchain.sh
	@swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)
	@scripts/check-imports.sh
	@swift scripts/tokens.swift check
	@scripts/check-colors.sh

format: web-install ## Format the Swift and web sources in place
	@swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)
	@cd web && pnpm exec prettier --write --log-level warn .

web-install: $(WEB_STAMP) ## Install the web workspace's pinned packages from its lockfile

$(WEB_STAMP): web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml
	@cd web && pnpm install --frozen-lockfile --reporter=silent
	@touch $@

lint-web: web-install ## Lint and check the formatting of the web sources
	@echo "== web lint"
	@cd web && pnpm exec eslint . && pnpm exec prettier --check --log-level warn .

types-web: web-install ## Type-check the web sources and Svelte components
	@echo "== web types"
	@cd web && pnpm exec svelte-kit sync && pnpm exec svelte-check --tsconfig ./tsconfig.json --fail-on-warnings --output human

test-web: web-install ## Run the web unit tests
	@echo "== web tests"
	@cd web && pnpm exec vitest run

build-web: web-install ## Build the web app for production (web/build, adapter-node)
	@echo "== web build"
	@cd web && pnpm exec vite build --logLevel warn

smoke-web: build-web catalog-export ## Boot the production web server and check every route it serves, with the release catalog in a throwaway PostgreSQL
	@scripts/web-smoke.sh
	@scripts/with-catalog.sh sh -c 'cd web && DBW_TEST_BUILD=1 pnpm exec vitest run'

serve-web: build-web catalog-export ## Serve the SvelteKit site's production build on http://localhost:8080 (PORT=…), with the release catalog and the component gallery
	@scripts/with-catalog.sh sh -c 'cd web && HOST=127.0.0.1 PORT=$(PORT) DBW_ENV=development node server.ts'

check-web: lint-web types-web test-web smoke-web check-export db-drift test-db ## The web part of make check

audit-web: web-install ## Check the web's production dependencies for published advisories (needs the network; docs/decisions.md E62)
	@cd web && pnpm audit --prod

test-domain-browser: web-install ## Run the shared engine cases in headless Firefox (docs/engine.md, "Parity")
	@echo "== domain cases in a browser"
	@cd web && node scripts/domain-browser.ts

CATALOG_EXPORT := build/catalog/catalog-export.json

catalog-export: check-catalog ## Export the release catalog as JSON for the PostgreSQL import
	@swift run --package-path Packages/CatalogCompiler --quiet catalog export \
		--catalog build/catalog/Catalog-release.sqlite --output $(CATALOG_EXPORT)

check-export: catalog-export web-install ## Check the release catalog's export as the import will
	@cd web && node scripts/catalog-import.ts --check ../$(CATALOG_EXPORT)

db-generate: web-install ## Generate a SQL migration in web/drizzle/ from web/src/lib/server/db/schema.ts (NAME=…)
	@cd web && pnpm exec drizzle-kit generate $(if $(NAME),--name $(NAME))

db-drift: web-install ## Fail if web/src/lib/server/db/schema.ts has changes no migration in web/drizzle/ holds
	@scripts/db-drift.sh

test-db: catalog-export web-install ## Test migrations, the catalog import, and the roles on a throwaway PostgreSQL
	@echo "== web database tests"
	@cd web && DBW_TEST_DB=1 DBW_REPOSITORY_EXPORT="$(CURDIR)/$(CATALOG_EXPORT)" \
		../scripts/with-postgres.sh pnpm exec vitest run

strings: build ## Add the app's new interface strings to its String Catalog and drop stale ones
	@swift scripts/strings.swift sync

check-strings: ## Check the String Catalog against the last build's strings (after test-app)
	@swift scripts/strings.swift check

tour: tour-app tour-web ## Visit every section in light and dark in the app and on the web, saving screenshots

tour-app: generate ## Every app UI test in the simulator: the tour in light and dark, the accessibility audit on every screen (docs/accessibility.md), and every critical flow (P17.10); screenshots go to screenshots/app/
	@mkdir -p screenshots/app
	@TEST_RUNNER_DBW_SCREENSHOTS="$(CURDIR)/screenshots/app" scripts/xcodebuild.sh tour-app \
		-destination "$$(scripts/sim-destination.sh)" -only-testing:AppUITests test

tour-web: build-web catalog-export ## Tour the SvelteKit site and every web flow in Firefox (WebDriver), Chrome (DevTools, phone widths too) and Safari (safaridriver, a visible window), with the release catalog; screenshots go to screenshots/web/
	@scripts/with-catalog.sh sh -c 'swift scripts/webtour.swift && DBW_WEBDRIVER=chrome swift scripts/webtour.swift && DBW_WEBDRIVER=safari swift scripts/webtour.swift'

check: lint check-web catalog check-catalog test-packages test-app check-strings ## The gate before every commit
	@echo "check: all passed"

check-full: check audit-web test-domain-browser tour-web tour-app test-linux ## The milestone gate: check, the production dependencies' advisories, the engine cases in a browser, both tours in light and dark, and Linux
	@echo "check-full: all passed"

check-signing: ## Check that this Mac can sign and upload the app: Xcode, the team's certificate, an Apple ID (docs/release.md)
	@scripts/check-signing.sh

archive: ## Build a signed Release archive for TestFlight (docs/release.md)
	@scripts/archive.sh

testflight: ## Upload build/DayByWord.xcarchive to App Store Connect (docs/release.md)
	@scripts/testflight.sh

deploy: ## Deploy origin/main to daybyword.com: build and check on the host, a candidate first, then live (docs/deploy.md)
	@deploy/bin/release.sh

clean: ## Remove build products and the generated Xcode project
	rm -rf build Packages/*/.build apple/DayByWord.xcodeproj web/build web/.svelte-kit web/node_modules
