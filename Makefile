TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-scheme 'swiftlint' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

SWIFT_BUILD_FLAGS=--configuration release -Xlinker -dead_strip

SWIFTLINT_EXECUTABLE_PARENT=.build/universal
SWIFTLINT_EXECUTABLE=$(SWIFTLINT_EXECUTABLE_PARENT)/swiftlint

ARTIFACT_BUNDLE_PATH=$(TEMPORARY_FOLDER)/SwiftLintBinary.artifactbundle

TSAN_LIB=$(subst bin/swift,lib/swift/clang/lib/darwin/libclang_rt.tsan_osx_dynamic.dylib,$(shell xcrun --find swift))
TSAN_SWIFT_BUILD_FLAGS=-Xswiftc -sanitize=thread
TSAN_TEST_BUNDLE=$(shell swift build $(TSAN_SWIFT_BUILD_FLAGS) --show-bin-path)/SwiftLintPackageTests.xctest
TSAN_XCTEST=$(shell xcrun --find xctest)

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin
LICENSE_PATH="$(shell pwd)/LICENSE"

OUTPUT_PACKAGE=SwiftLint.pkg

VERSION_STRING=$(shell ./tools/get-version)

.PHONY: all clean build install package test uninstall docs

all: build

sourcery: Source/SwiftLintBuiltInRules/Models/BuiltInRules.swift Source/SwiftLintCore/Models/ReportersList.swift Tests/GeneratedTests/GeneratedTests.swift

Source/SwiftLintBuiltInRules/Models/BuiltInRules.swift: Source/SwiftLintBuiltInRules/Rules/**/*.swift .sourcery/BuiltInRules.stencil
	./tools/sourcery --sources Source/SwiftLintBuiltInRules/Rules --templates .sourcery/BuiltInRules.stencil --output .sourcery
	mv .sourcery/BuiltInRules.generated.swift Source/SwiftLintBuiltInRules/Models/BuiltInRules.swift

Source/SwiftLintCore/Models/ReportersList.swift: Source/SwiftLintCore/Reporters/*.swift .sourcery/ReportersList.stencil
	./tools/sourcery --sources Source/SwiftLintCore/Reporters --templates .sourcery/ReportersList.stencil --output .sourcery
	mv .sourcery/ReportersList.generated.swift Source/SwiftLintCore/Models/ReportersList.swift

Tests/GeneratedTests/GeneratedTests.swift: Source/SwiftLint*/Rules/**/*.swift .sourcery/GeneratedTests.stencil
	./tools/sourcery --sources Source/SwiftLintCore/Rules --sources Source/SwiftLintBuiltInRules/Rules --templates .sourcery/GeneratedTests.stencil --output .sourcery
	mv .sourcery/GeneratedTests.generated.swift Tests/GeneratedTests/GeneratedTests.swift

test: clean_xcode
	$(BUILD_TOOL) $(XCODEFLAGS) test

test_tsan:
	swift build --build-tests $(TSAN_SWIFT_BUILD_FLAGS)
	DYLD_INSERT_LIBRARIES=$(TSAN_LIB) $(TSAN_XCTEST) $(TSAN_TEST_BUNDLE)

write_xcodebuild_log:
	xcodebuild -scheme swiftlint clean build-for-testing -destination "platform=macOS" > xcodebuild.log

analyze: write_xcodebuild_log
	swift run -c release swiftlint analyze --strict --compiler-log-path xcodebuild.log

analyze_autocorrect: write_xcodebuild_log
	swift run -c release swiftlint analyze --autocorrect --compiler-log-path xcodebuild.log

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	rm -f "./*.zip" "bazel.tar.gz" "bazel.tar.gz.sha256"
	swift package clean

clean_xcode:
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

build:
	mkdir -p "$(SWIFTLINT_EXECUTABLE_PARENT)"
	bazel build --config release universal_swiftlint
	$(eval SWIFTLINT_BINARY := $(shell bazel cquery --config release --output=files universal_swiftlint))
	mv "$(SWIFTLINT_BINARY)" "$(SWIFTLINT_EXECUTABLE)"
	chmod +w "$(SWIFTLINT_EXECUTABLE)"
	strip -rSTX "$(SWIFTLINT_EXECUTABLE)"

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

spm_artifactbundle_macos: installables
	mkdir -p "$(ARTIFACT_BUNDLE_PATH)/swiftlint-$(VERSION_STRING)-macos/bin"
	sed 's/__VERSION__/$(VERSION_STRING)/g' tools/info-macos.json.template > "$(ARTIFACT_BUNDLE_PATH)/info.json"
	cp -f "$(SWIFTLINT_EXECUTABLE)" "$(ARTIFACT_BUNDLE_PATH)/swiftlint-$(VERSION_STRING)-macos/bin"
	cp -f "$(LICENSE_PATH)" "$(ARTIFACT_BUNDLE_PATH)"
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "SwiftLintBinary.artifactbundle") > "./SwiftLintBinary-macos.artifactbundle.zip"

zip_linux: docker_image
	$(eval TMP_FOLDER := $(shell mktemp -d))
	docker run swiftlint cat /usr/bin/swiftlint > "$(TMP_FOLDER)/swiftlint"
	chmod +x "$(TMP_FOLDER)/swiftlint"
	cp -f "$(LICENSE_PATH)" "$(TMP_FOLDER)"
	(cd "$(TMP_FOLDER)"; zip -yr - "swiftlint" "LICENSE") > "./swiftlint_linux.zip"

zip_linux_release:
	$(eval TMP_FOLDER := $(shell mktemp -d))
	docker run --platform linux/amd64 "ghcr.io/realm/swiftlint:$(VERSION_STRING)" cat /usr/bin/swiftlint > "$(TMP_FOLDER)/swiftlint"
	chmod +x "$(TMP_FOLDER)/swiftlint"
	cp -f "$(LICENSE_PATH)" "$(TMP_FOLDER)"
	(cd "$(TMP_FOLDER)"; zip -yr - "swiftlint" "LICENSE") > "./swiftlint_linux.zip"
	gh release upload "$(VERSION_STRING)" swiftlint_linux.zip

package: build
	$(eval PACKAGE_ROOT := $(shell mktemp -d))
	cp "$(SWIFTLINT_EXECUTABLE)" "$(PACKAGE_ROOT)"
	pkgbuild \
		--identifier "io.realm.swiftlint" \
		--install-location "/usr/local/bin" \
		--root "$(PACKAGE_ROOT)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

bazel_release:
	bazel build :release
	mv bazel-bin/bazel.tar.gz bazel-bin/bazel.tar.gz.sha256 .

docker_image:
	docker build --platform linux/amd64 --force-rm --tag swiftlint .

docker_test:
	docker run -v `pwd`:`pwd` -w `pwd` --name swiftlint --rm swift:5.7-focal swift test --parallel

docker_htop:
	docker run --platform linux/amd64 -it --rm --pid=container:swiftlint terencewestphal/htop || reset

# https://irace.me/swift-profiling
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build-for-testing | grep -E ^[1-9]{1}[0-9]*.[0-9]+ms | sort -n

publish:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) swiftlint
	bundle install
	bundle exec pod trunk push SwiftLint.podspec

docs:
	swift run swiftlint generate-docs
	bundle install
	bundle exec jazzy

get_version:
	@echo "$(VERSION_STRING)"

release:
ifneq ($(strip $(shell git status --untracked-files=no --porcelain 2>/dev/null)),)
	$(error git state is not clean)
endif
	$(eval NEW_VERSION_AND_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval NEW_VERSION := $(shell echo $(NEW_VERSION_AND_NAME) | sed 's/:.*//' ))
	@sed -i '' 's/## Main/## $(NEW_VERSION_AND_NAME)/g' CHANGELOG.md
	@sed 's/__VERSION__/$(NEW_VERSION)/g' tools/Version.swift.template > Source/SwiftLintCore/Models/Version.swift
	@sed -e '3s/.*/    version = "$(NEW_VERSION)",/' -i '' MODULE.bazel
	make clean
	make package
	make bazel_release
	make portable_zip
	make spm_artifactbundle_macos
	./tools/update-artifact-bundle.sh "$(NEW_VERSION)"
	git commit -a -m "release $(NEW_VERSION)"
	git tag -a $(NEW_VERSION) -m "$(NEW_VERSION_AND_NAME)"
	git push origin HEAD
	git push origin $(NEW_VERSION)
	./tools/create-github-release.sh "$(NEW_VERSION)"
	make publish
	./tools/add-new-changelog-section.sh
	git commit -a -m "Add new changelog section"
	git push origin HEAD

%:
	@:
