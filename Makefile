TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-scheme 'swiftlint' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

SWIFT_BUILD_FLAGS=--configuration release
UNAME=$(shell uname)
ifeq ($(UNAME), Darwin)
USE_SWIFT_STATIC_STDLIB:=$(shell test -d $$(dirname $$(xcrun --find swift))/../lib/swift_static/macosx && echo yes)
ifeq ($(USE_SWIFT_STATIC_STDLIB), yes)
SWIFT_BUILD_FLAGS+= -Xswiftc -static-stdlib
endif
# SwiftPM 5.3 uses the `XCBuild.framework` to generate a universal binary when it receives multiple `--arch` options.
SWIFT_BUILD_ARCHS:= arm64 x86_64
# If SwiftPM supports `--arch $(1)` and `swiftc` succeeds in building with `-target $(1)-apple-macos10.9`, then produce `--arch $(1)`.
ARCH_OPTION=$(shell swift build --show-bin-path --arch $(1) &>/dev/null && echo ''|swiftc -target $(1)-apple-macos10.9 - -o /dev/null &>/dev/null && echo "--arch" $(1))
SWIFT_BUILD_FLAGS+=$(foreach arch,$(SWIFT_BUILD_ARCHS),$(call ARCH_OPTION,$(arch)))
endif # Darwin

SWIFTLINT_EXECUTABLE=$(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/swiftlint

TSAN_LIB=$(subst bin/swift,lib/swift/clang/lib/darwin/libclang_rt.tsan_osx_dynamic.dylib,$(shell xcrun --find swift))
TSAN_SWIFT_BUILD_FLAGS=-Xswiftc -sanitize=thread
TSAN_TEST_BUNDLE=$(shell swift build $(TSAN_SWIFT_BUILD_FLAGS) --show-bin-path)/SwiftLintPackageTests.xctest
TSAN_XCTEST=$(shell xcrun --find xctest)

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin
LICENSE_PATH="$(shell pwd)/LICENSE"

OUTPUT_PACKAGE=SwiftLint.pkg

VERSION_STRING="$(shell ./script/get-version)"

.PHONY: all clean build install package test uninstall docs

all: build

sourcery: Source/SwiftLintFramework/Models/PrimaryRuleList.swift Tests/SwiftLintFrameworkTests/AutomaticRuleTests.generated.swift Tests/LinuxMain.swift

Tests/LinuxMain.swift: Tests/*/*.swift .sourcery/LinuxMain.stencil
	sourcery --sources Tests --exclude-sources Tests/SwiftLintFrameworkTests/Resources --templates .sourcery/LinuxMain.stencil --output .sourcery --force-parse generated
	mv .sourcery/LinuxMain.generated.swift Tests/LinuxMain.swift

Source/SwiftLintFramework/Models/PrimaryRuleList.swift: Source/SwiftLintFramework/Rules/**/*.swift .sourcery/PrimaryRuleList.stencil
	sourcery --sources Source/SwiftLintFramework/Rules --templates .sourcery/PrimaryRuleList.stencil --output .sourcery
	mv .sourcery/PrimaryRuleList.generated.swift Source/SwiftLintFramework/Models/PrimaryRuleList.swift

Tests/SwiftLintFrameworkTests/AutomaticRuleTests.generated.swift: Source/SwiftLintFramework/Rules/**/*.swift .sourcery/AutomaticRuleTests.stencil
	sourcery --sources Source/SwiftLintFramework/Rules --templates .sourcery/AutomaticRuleTests.stencil --output .sourcery
	mv .sourcery/AutomaticRuleTests.generated.swift Tests/SwiftLintFrameworkTests/AutomaticRuleTests.generated.swift

test: clean_xcode
	$(BUILD_TOOL) $(XCODEFLAGS) test

test_tsan:
	swift build --build-tests $(TSAN_SWIFT_BUILD_FLAGS)
	DYLD_INSERT_LIBRARIES=$(TSAN_LIB) $(TSAN_XCTEST) $(TSAN_TEST_BUNDLE)

write_xcodebuild_log:
	xcodebuild -scheme swiftlint clean build-for-testing > xcodebuild.log

analyze: write_xcodebuild_log
	swift run -c release swiftlint analyze --strict --compiler-log-path xcodebuild.log

analyze_autocorrect: write_xcodebuild_log
	swift run -c release swiftlint analyze --autocorrect --compiler-log-path xcodebuild.log

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	rm -f "./portable_swiftlint.zip"
	swift package clean

clean_xcode:
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

build:
	swift build $(SWIFT_BUILD_FLAGS)

build_with_disable_sandbox:
	swift build --disable-sandbox $(SWIFT_BUILD_FLAGS)

install: build
	install -d "$(BINARIES_FOLDER)"
	install "$(SWIFTLINT_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	rm -f "$(BINARIES_FOLDER)/swiftlint"

installables: build
	install -d "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	install "$(SWIFTLINT_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"

prefix_install: build_with_disable_sandbox
	install -d "$(PREFIX)/bin/"
	install "$(SWIFTLINT_EXECUTABLE)" "$(PREFIX)/bin/"

portable_zip: installables
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint" "$(TEMPORARY_FOLDER)"
	cp -f "$(LICENSE_PATH)" "$(TEMPORARY_FOLDER)"
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "swiftlint" "LICENSE") > "./portable_swiftlint.zip"

zip_linux: docker_image
	$(eval TMP_FOLDER := $(shell mktemp -d))
	docker run swiftlint cat /usr/bin/swiftlint > "$(TMP_FOLDER)/swiftlint"
	chmod +x "$(TMP_FOLDER)/swiftlint"
	cp -f "$(LICENSE_PATH)" "$(TMP_FOLDER)"
	(cd "$(TMP_FOLDER)"; zip -yr - "swiftlint" "LICENSE") > "./swiftlint_linux.zip"

package: installables
	pkgbuild \
		--identifier "io.realm.swiftlint" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

release: package portable_zip zip_linux

docker_image:
	docker build --force-rm --tag swiftlint .

docker_test:
	docker run -v `pwd`:`pwd` -w `pwd` --name swiftlint --rm swift:5.3 swift test --parallel

docker_htop:
	docker run -it --rm --pid=container:swiftlint terencewestphal/htop || reset

# https://irace.me/swift-profiling
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build-for-testing | grep -E ^[1-9]{1}[0-9]*.[0-9]+ms | sort -n

publish:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) swiftlint
	pod trunk push SwiftLintFramework.podspec
	pod trunk push SwiftLint.podspec

docs:
	swift run swiftlint generate-docs
	bundle install
	bundle exec jazzy

get_version:
	@echo $(VERSION_STRING)

push_version:
ifneq ($(strip $(shell git status --untracked-files=no --porcelain 2>/dev/null)),)
	$(error git state is not clean)
endif
	$(eval NEW_VERSION_AND_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval NEW_VERSION := $(shell echo $(NEW_VERSION_AND_NAME) | sed 's/:.*//' ))
	@sed -i '' 's/## Master/## $(NEW_VERSION_AND_NAME)/g' CHANGELOG.md
	@sed 's/__VERSION__/$(NEW_VERSION)/g' script/Version.swift.template > Source/SwiftLintFramework/Models/Version.swift
	git commit -a -m "release $(NEW_VERSION)"
	git tag -a $(NEW_VERSION) -m "$(NEW_VERSION_AND_NAME)"
	git push origin master
	git push origin $(NEW_VERSION)

%:
	@:
