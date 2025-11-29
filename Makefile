########################
MAKEFILE_VERSION=2.1.0
########################

# Project Configuration
WORKSPACE_TYPE := $(WORKSPACE_TYPE_SPECIFIED)
WORKSPACE_NAME=$(shell cat .workspace-name)
SCHEME_NAME=$(shell cat .scheme-name)
DERIVED_DATA_PATH=.derivedData
DOCS_DATA_PATH=docsData

# Platform Destinations
PLATFORM_IOS='iOS Simulator,name=iPhone 17 Pro,OS=latest'
PLATFORM_MACOS='platform=macOS'

# Build Options
USE_RELATIVE_DERIVED_DATA=-derivedDataPath $(DERIVED_DATA_PATH)

XCODEBUILD_OPTIONS_BASE=\
	-configuration Debug \
	$(USE_RELATIVE_DERIVED_DATA) \
	-scheme $(SCHEME_NAME) \
	-usePackageSupportBuiltinSCM

XCODEBUILD_OPTIONS_IOS=$(XCODEBUILD_OPTIONS_BASE) \
	-destination platform=$(PLATFORM_IOS) \
	-workspace $(WORKSPACE_NAME).xcworkspace

XCODEBUILD_OPTIONS_MACOS=$(XCODEBUILD_OPTIONS_BASE) \
	-destination $(PLATFORM_MACOS) \
	-workspace $(WORKSPACE_NAME).xcworkspace

XCODEBUILD_OPTIONS_DOCUMENTATION=\
	docbuild \
	-destination 'generic/platform=iOS' \
	-scheme $(SCHEME_NAME) \
	-derivedDataPath '.build/derived-data/'

# Colors for output
COLOR_RESET=\033[0m
COLOR_BLUE=\033[36m
COLOR_GREEN=\033[32m
COLOR_YELLOW=\033[33m
COLOR_RED=\033[31m

.PHONY: help
help: ## Print all help arguments
	@echo "\n=========================================================="
	@echo "      $(WORKSPACE_NAME) MAKEFILE HELP (Version $(MAKEFILE_VERSION))"
	@echo "==========================================================\n"
	@echo "The Makefile contains all commands necessary for $(WORKSPACE_NAME)\n"
	@echo "USAGE: make $(COLOR_BLUE)<command>$(COLOR_RESET)\n"
	@echo "COMMANDS:"
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(COLOR_BLUE)%-30s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo "\nConfiguration Files:"
	@echo "$(COLOR_BLUE).app-version$(COLOR_RESET)       Version number of the project"
	@echo "$(COLOR_BLUE).app-buildnumber$(COLOR_RESET)   Build number of the project"
	@echo "$(COLOR_BLUE).tuist-version$(COLOR_RESET)     Tuist version to use\n"

######### CLEAN #########

.PHONY: clean
clean: ## Remove all generated files and folders
	@echo "$(COLOR_YELLOW)Yeeting all the rubbish out the window...$(COLOR_RESET)"
	rm -rf $(DERIVED_DATA_PATH)
	rm -rf *.xcodeproj
	rm -rf *.xcworkspace
	rm -rf Derived
	rm -rf .build
	rm -rf ~/Library/Developer/Xcode/DerivedData/*
	tuist clean
	@echo "$(COLOR_GREEN)✓ Bob's your uncle! All clean now.$(COLOR_RESET)"

.PHONY: deep-clean
deep-clean: clean ## Deep clean including dependencies
	@echo "$(COLOR_YELLOW)Going full scorched earth here, mate...$(COLOR_RESET)"
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(WORKSPACE_NAME)-*
	@echo "$(COLOR_GREEN)✓ Blimey! That's proper clean that is.$(COLOR_RESET)"

######### FORMATTING #########

.PHONY: format
format: ## Format code and files
	@echo "$(COLOR_YELLOW)Making the code look proper fancy...$(COLOR_RESET)"
	swiftformat .
	swiftlint --autocorrect
	@echo "$(COLOR_GREEN)✓ Brilliant! Code's looking mint.$(COLOR_RESET)"

.PHONY: lint
lint: ## Run linting on code and files
	@echo "$(COLOR_YELLOW)Having a gander at the code quality...$(COLOR_RESET)"
	swiftformat --cache ignore --lint .
	swiftlint --config ./.swiftlint.yml --strict
	@echo "$(COLOR_GREEN)✓ Smashing! No dodgy bits found.$(COLOR_RESET)"

######### BUILD #########

.PHONY: build-ios
build-ios: ## Build for iOS
	@echo "$(COLOR_YELLOW)Cooking up an iOS build, hang about...$(COLOR_RESET)"
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build | xcbeautify

.PHONY: build-macos
build-macos: ## Build for macOS
	@echo "$(COLOR_YELLOW)Whipping up a macOS build...$(COLOR_RESET)"
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_MACOS) build | xcbeautify

.PHONY: build-all
build-all: build-ios build-macos ## Build for all platforms

######### TESTING #########

.PHONY: test-ios
test-ios: ## Run tests on iOS
	@echo "$(COLOR_YELLOW)Running iOS tests, fingers crossed...$(COLOR_RESET)"
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) test | xcbeautify

.PHONY: test-macos
test-macos: ## Run tests on macOS
	@echo "$(COLOR_YELLOW)Testing on macOS, easy does it...$(COLOR_RESET)"
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_MACOS) test | xcbeautify

.PHONY: test-all
test-all: test-ios test-macos ## Run tests on all platforms

######### TUIST #########

.PHONY: generate
generate: ## Generate the Xcode project/workspace
	@echo "$(COLOR_YELLOW)Conjuring up the Xcode project...$(COLOR_RESET)"
	tuist clean
	tuist generate --no-open
	@echo "$(COLOR_GREEN)✓ Project's ready to rock - off you pop!$(COLOR_RESET)"

.PHONY: open
open: ## Generate and open the Xcode workspace
	@echo ""
	@echo "$(COLOR_BLUE)╔═════════════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)║  Yeah! AsyncCachedImage wants to have a chat with Xcode!             ║$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)║  Just typed 'make open' did ya? Proper clever, you are.             ║$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)╚═════════════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_YELLOW)[i] Fun fact: This SDK caches images faster than you can say$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)    'supercalifragilisticexpialidocious'! iOS AND macOS, innit.$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)    Memory issues? Not on my watch, guv'nor!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BLUE)[>] Right then, spitting in the hands, let's get cracking...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)[>] Hold your horses... fetching assets from the void...$(COLOR_RESET)"
	tuist clean
	@echo ""
	@echo "$(COLOR_GREEN)[>] A speedy cache needs a speedy Xcode. Here we go!$(COLOR_RESET)"
	@echo ""
	tuist generate
	@echo ""
	@echo "$(COLOR_GREEN)╔════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)║  [✓] Xcode's open - cheerio and happy coding!          ║$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)╚════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""

.PHONY: edit
edit: ## Edit the Tuist configuration
	@echo "$(COLOR_YELLOW)Cracking open Tuist for editing...$(COLOR_RESET)"
	tuist edit

.PHONY: graph
graph: ## Generate dependency graph
	@echo "$(COLOR_YELLOW)Drawing up the dependency graph...$(COLOR_RESET)"
	tuist graph
	@echo "$(COLOR_GREEN)✓ Graph's ready for your viewing pleasure$(COLOR_RESET)"

######### SETUP #########

.PHONY: setup
setup: setup-brew setup-tuist ## Install all required tools
	@echo "$(COLOR_GREEN)✓ Setup's done and dusted!$(COLOR_RESET)"

.PHONY: setup-brew
setup-brew: ## Install all Homebrew packages
	@echo "$(COLOR_YELLOW)Installing the Homebrew goodies...$(COLOR_RESET)"
	brew install -q \
		swiftlint \
		swiftformat \
		xcbeautify \
		swiftgen \
		markdownlint-cli \
		jq
	@echo "$(COLOR_GREEN)✓ All Homebrew bits are sorted$(COLOR_RESET)"

.PHONY: setup-tuist
setup-tuist: ## Install Tuist
ifeq ($(shell which tuist),)
	@echo "$(COLOR_YELLOW)Installing Tuist...$(COLOR_RESET)"
	curl -Ls https://install.tuist.io | bash
	@echo "$(COLOR_GREEN)✓ Tuist installed$(COLOR_RESET)"
else
	@echo "$(COLOR_GREEN)✓ Tuist already installed$(COLOR_RESET)"
endif

######### VERSION MANAGEMENT #########

.PHONY: bump-major
bump-major: ## Bump the major version (X.0.0)
	@echo "$(COLOR_YELLOW)Bumping major version...$(COLOR_RESET)"
	@CURRENT=$$(cat .app-version); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	NEW_MAJOR=$$((MAJOR + 1)); \
	echo "$$NEW_MAJOR.0.0" > .app-version; \
	echo "$(COLOR_GREEN)✓ Version bumped to $$NEW_MAJOR.0.0$(COLOR_RESET)"

.PHONY: bump-minor
bump-minor: ## Bump the minor version (x.X.0)
	@echo "$(COLOR_YELLOW)Bumping minor version...$(COLOR_RESET)"
	@CURRENT=$$(cat .app-version); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	NEW_MINOR=$$((MINOR + 1)); \
	echo "$$MAJOR.$$NEW_MINOR.0" > .app-version; \
	echo "$(COLOR_GREEN)✓ Version bumped to $$MAJOR.$$NEW_MINOR.0$(COLOR_RESET)"

.PHONY: bump-patch
bump-patch: ## Bump the patch version (x.x.X)
	@echo "$(COLOR_YELLOW)Bumping patch version...$(COLOR_RESET)"
	@CURRENT=$$(cat .app-version); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	NEW_PATCH=$$((PATCH + 1)); \
	echo "$$MAJOR.$$MINOR.$$NEW_PATCH" > .app-version; \
	echo "$(COLOR_GREEN)✓ Version bumped to $$MAJOR.$$MINOR.$$NEW_PATCH$(COLOR_RESET)"

.PHONY: bump-build
bump-build: ## Bump the build number
	@echo "$(COLOR_YELLOW)Bumping build number...$(COLOR_RESET)"
	@CURRENT=$$(cat .app-buildnumber); \
	NEW=$$((CURRENT + 1)); \
	echo "$$NEW" > .app-buildnumber; \
	echo "$(COLOR_GREEN)✓ Build number bumped to $$NEW$(COLOR_RESET)"

######### CI/CD #########

.PHONY: ci-setup
ci-setup: ci-setup-brew ci-setup-tuist ## Setup CI environment

.PHONY: ci-setup-brew
ci-setup-brew: ## Install CI dependencies via Homebrew
	@echo "$(COLOR_YELLOW)Installing CI dependencies...$(COLOR_RESET)"
	brew install -q xcbeautify swiftlint
	@echo "$(COLOR_GREEN)✓ CI dependencies installed$(COLOR_RESET)"

.PHONY: ci-setup-tuist
ci-setup-tuist: ## Install and setup Tuist for CI
	@echo "$(COLOR_YELLOW)Installing Tuist via mise...$(COLOR_RESET)"
	mise install tuist@$(shell cat .tuist-version)
	mise use tuist@$(shell cat .tuist-version)
	tuist install
	@echo "$(COLOR_GREEN)✓ Tuist installed$(COLOR_RESET)"

.PHONY: ci-generate
ci-generate: ## Generate project for CI
	@echo "$(COLOR_YELLOW)Generating project...$(COLOR_RESET)"
	tuist generate --no-open
	@echo "$(COLOR_GREEN)✓ Project generated$(COLOR_RESET)"

.PHONY: ci-test-ios
ci-test-ios: ## Run package tests on iOS Simulator (CI only)
	@echo "$(COLOR_YELLOW)Running iOS tests, fingers crossed...$(COLOR_RESET)"
	set -o pipefail && swift test --filter AsyncCachedImageTests 2>&1 | xcbeautify
	@echo "$(COLOR_GREEN)✓ Lovely jubbly! iOS tests passed.$(COLOR_RESET)"

.PHONY: ci-test-macos
ci-test-macos: ## Run package tests on macOS (CI only)
	@echo "$(COLOR_YELLOW)Testing on macOS, easy does it...$(COLOR_RESET)"
	set -o pipefail && swift test 2>&1 | xcbeautify
	@echo "$(COLOR_GREEN)✓ Blinding! macOS tests are sorted.$(COLOR_RESET)"

######### TUIST MAINTENANCE #########

.PHONY: tuist-check-update
tuist-check-update: ## Check for Tuist updates
	@if [ -z $$(which jq) ]; then \
		echo "$(COLOR_YELLOW)jq not installed. Install with: brew install jq$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Checking for Tuist updates...$(COLOR_RESET)"; \
		LATEST_VERSION=$$(curl -L -s https://api.github.com/repos/tuist/tuist/releases/latest | jq -r .tag_name); \
		CURRENT_VERSION=$$(cat .tuist-version); \
		if [ "$$LATEST_VERSION" == "$$CURRENT_VERSION" ]; then \
			echo "$(COLOR_GREEN)✓ You're on the latest version: $$CURRENT_VERSION$(COLOR_RESET)"; \
		else \
			echo "$(COLOR_BLUE)Update available: $$LATEST_VERSION (current: $$CURRENT_VERSION)$(COLOR_RESET)"; \
			echo "$$LATEST_VERSION" > .tuist-version; \
			echo "$(COLOR_GREEN)✓ .tuist-version has been updated$(COLOR_RESET)"; \
		fi \
	fi

######### DEVELOPMENT WORKFLOW #########

.PHONY: dev
dev: clean format generate open ## Full development setup: clean, format, generate, open

.PHONY: reset
reset: deep-clean generate ## Reset project completely and regenerate

.PHONY: verify
verify: format lint build-all test-all ## Verify code quality and functionality

######### DOCUMENTATION #########

.PHONY: docs
docs: ## Generate documentation
	@echo "$(COLOR_YELLOW)Generating documentation...$(COLOR_RESET)"
	xcodebuild $(XCODEBUILD_OPTIONS_DOCUMENTATION)
	@echo "$(COLOR_GREEN)✓ Documentation is ready$(COLOR_RESET)"

######### UTILITY #########

.PHONY: info
info: ## Display project information
	@echo ""
	@echo "$(COLOR_BLUE)Project Info$(COLOR_RESET)"
	@echo "===================="
	@echo "$(COLOR_BLUE)Name:$(COLOR_RESET)              $(WORKSPACE_NAME)"
	@echo "$(COLOR_BLUE)Scheme:$(COLOR_RESET)            $(SCHEME_NAME)"
	@echo "$(COLOR_BLUE)Version:$(COLOR_RESET)           $$(cat .app-version)"
	@echo "$(COLOR_BLUE)Build:$(COLOR_RESET)             $$(cat .app-buildnumber)"
	@echo "$(COLOR_BLUE)Tuist Version:$(COLOR_RESET)     $$(cat .tuist-version)"
	@echo "$(COLOR_BLUE)Swift Version:$(COLOR_RESET)     $$(swift --version | head -n 1)"
	@echo "$(COLOR_BLUE)Xcode Version:$(COLOR_RESET)     $$(xcodebuild -version | head -n 1)"
	@echo ""

.PHONY: validate
validate: ## Validate project configuration
	@echo "$(COLOR_YELLOW)Validating project configuration...$(COLOR_RESET)"
	@test -f .app-version || (echo "$(COLOR_YELLOW)⚠ .app-version missing$(COLOR_RESET)" && exit 1)
	@test -f .app-buildnumber || (echo "$(COLOR_YELLOW)⚠ .app-buildnumber missing$(COLOR_RESET)" && exit 1)
	@test -f .tuist-version || (echo "$(COLOR_YELLOW)⚠ .tuist-version missing$(COLOR_RESET)" && exit 1)
	@test -f Project.swift || (echo "$(COLOR_YELLOW)⚠ Project.swift missing$(COLOR_RESET)" && exit 1)
	@test -f Tuist/Workspace.swift || (echo "$(COLOR_YELLOW)⚠ Workspace.swift missing$(COLOR_RESET)" && exit 1)
	@echo "$(COLOR_GREEN)✓ Project configuration looks good$(COLOR_RESET)"

# Default target
.DEFAULT_GOAL := help