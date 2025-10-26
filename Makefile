TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild
MIMALLOC_LICENSE=third_party_licenses/mimalloc-LICENSE

XCODEFLAGS=-scheme 'swiftlint' \
	-destination 'platform=macOS' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

SWIFT_BUILD_FLAGS=--configuration release -Xlinker -dead_strip

ARTIFACT_BUNDLE_PATH=$(TEMPORARY_FOLDER)/SwiftLintBinary.artifactbundle

TSAN_LIB=$(subst bin/swift,lib/swift/clang/lib/darwin/libclang_rt.tsan_osx_dynamic.dylib,$(shell xcrun --find swift))
TSAN_SWIFT_BUILD_FLAGS=-Xswiftc -sanitize=thread
TSAN_TEST_BUNDLE=$(shell swift build $(TSAN_SWIFT_BUILD_FLAGS) --show-bin-path)/SwiftLintPackageTests.xctest
TSAN_XCTEST=$(shell xcrun --find xctest)

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin
OUTPUT_PACKAGE=SwiftLint.pkg

VERSION_STRING=$(shell ./tools/get-version)

.PHONY: all clean install package test uninstall docs register bazel_register test_tsan spm_linux_build spm_build_plugins spm_test write_xcodebuild_log analyze analyze_autocorrect clean_xcode build_with_disable_sandbox installables prefix_install portable_zip spm_artifactbundle zip_linux_release bazel_test bazel_test_tsan bazel_release docker_image docker_test docker_htop display_compilation_time formula_bump bundle_install oss_scan pod_publish pod_lint docs_linux get_version

all: swiftlint

register:
	swift run swiftlint-dev rules register
	swift run swiftlint-dev reporters register

bazel_register:
	bazel build //:swiftlint-dev
	./bazel-bin/swiftlint-dev rules register
	./bazel-bin/swiftlint-dev reporters register

test: clean_xcode
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean_xcode:
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

test_tsan:
	swift build --build-tests $(TSAN_SWIFT_BUILD_FLAGS)
	DYLD_INSERT_LIBRARIES=$(TSAN_LIB) $(TSAN_XCTEST) $(TSAN_TEST_BUNDLE)

spm_linux_build:
	swift build -c release -Xswiftc -static-stdlib --product swiftlint
	strip -s "$(shell swift build -c release --show-bin-path)/swiftlint"

spm_build_plugins:
	swift build -c release --product SwiftLintCommandPlugin
	swift build -c release --product SwiftLintBuildToolPlugin

spm_test:
	swift test --parallel -Xswiftc -DDISABLE_FOCUSED_EXAMPLES

write_xcodebuild_log:
	xcodebuild -scheme swiftlint clean build-for-testing -destination "platform=macOS" > xcodebuild.log

analyze: write_xcodebuild_log
	swift run -c release swiftlint analyze --strict --compiler-log-path xcodebuild.log

analyze_autocorrect: write_xcodebuild_log
	swift run -c release swiftlint analyze --autocorrect --compiler-log-path xcodebuild.log

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	rm -rf rule_docs/ docs/ .build/
	rm -f ./*.{zip,pkg} bazel.tar.gz bazel.tar.gz.sha256
	rm -f swiftlint swiftlint_{linux,static}_{amd64,arm64}
	swift package clean
	bazel clean --expunge
	bazel shutdown

swiftlint:
	bazel build --config release universal_swiftlint
	$(eval SWIFTLINT_BINARY := $(shell bazel cquery --config release --output=files universal_swiftlint))
	mv "$(SWIFTLINT_BINARY)" swiftlint
	chmod +w swiftlint
	strip -rSTX swiftlint

build_with_disable_sandbox:
	swift build --disable-sandbox $(SWIFT_BUILD_FLAGS)

install: swiftlint
	install -d "$(BINARIES_FOLDER)"
	install swiftlint "$(BINARIES_FOLDER)"

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	rm -f "$(BINARIES_FOLDER)/swiftlint"

installables: swiftlint
	install -d "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	install swiftlint "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"

prefix_install: build_with_disable_sandbox
	install -d "$(PREFIX)/bin/"
	install swiftlint "$(PREFIX)/bin/"

portable_zip: installables
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint" "$(TEMPORARY_FOLDER)"
	cp -f LICENSE "$(TEMPORARY_FOLDER)"
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "swiftlint" "LICENSE") > "./portable_swiftlint.zip"

spm_artifactbundle: swiftlint swiftlint_linux_amd64 swiftlint_linux_arm64
	mkdir -p $(ARTIFACT_BUNDLE_PATH)/macos $(ARTIFACT_BUNDLE_PATH)/linux/{amd,arm}64
	sed 's/__VERSION__/$(VERSION_STRING)/g' tools/info.json.template > "$(ARTIFACT_BUNDLE_PATH)/info.json"
	cp -f swiftlint "$(ARTIFACT_BUNDLE_PATH)/macos/swiftlint"
	cp -f swiftlint_linux_amd64 "$(ARTIFACT_BUNDLE_PATH)/linux/amd64/swiftlint"
	cp -f swiftlint_linux_arm64 "$(ARTIFACT_BUNDLE_PATH)/linux/arm64/swiftlint"
	cp -f LICENSE "$(ARTIFACT_BUNDLE_PATH)"
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "SwiftLintBinary.artifactbundle") > "./SwiftLintBinary.artifactbundle.zip"

zip_linux_release: swiftlint_linux_amd64 swiftlint_linux_arm64 swiftlint_static_amd64 swiftlint_static_arm64
	$(eval TMP_FOLDER := $(shell mktemp -d))
	cp -f swiftlint_linux_amd64 "$(TMP_FOLDER)/swiftlint"
	cp -f swiftlint_static_amd64 "$(TMP_FOLDER)/swiftlint-static"
	cp -f LICENSE "$(TMP_FOLDER)"
	cp -f "$(MIMALLOC_LICENSE)" "$(TMP_FOLDER)/LICENSE.mimalloc"
	(cd "$(TMP_FOLDER)"; zip -yr - "swiftlint" "swiftlint-static" "LICENSE" "LICENSE.mimalloc") > "./swiftlint_linux_amd64.zip"
	cp -f swiftlint_linux_arm64 "$(TMP_FOLDER)/swiftlint"
	cp -f swiftlint_static_arm64 "$(TMP_FOLDER)/swiftlint-static"
	(cd "$(TMP_FOLDER)"; zip -yr - "swiftlint" "swiftlint-static" "LICENSE" "LICENSE.mimalloc") > "./swiftlint_linux_arm64.zip"

package: swiftlint
	$(eval PACKAGE_ROOT := $(shell mktemp -d))
	cp swiftlint "$(PACKAGE_ROOT)"
	pkgbuild \
		--identifier "io.realm.swiftlint" \
		--install-location "/usr/local/bin" \
		--root "$(PACKAGE_ROOT)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

bazel_test:
	bazel test --test_env=SKIP_INTEGRATION_TESTS=true --test_output=errors //Tests/...

bazel_test_tsan:
	bazel test --test_output=errors --build_tests_only --features=tsan --test_timeout=1000 //Tests/...

bazel_release: swiftlint
	bazel build :release
	mv -f bazel-bin/bazel.tar.gz bazel-bin/bazel.tar.gz.sha256 .

docker_image:
	docker build --platform linux/amd64 --force-rm --tag swiftlint .

docker_test:
	docker run -v `pwd`:`pwd` -w `pwd` --name swiftlint --rm swift:6.0-noble swift test --parallel

docker_htop:
	docker run --platform linux/amd64 -it --rm --pid=container:swiftlint terencewestphal/htop || reset

# https://irace.me/swift-profiling
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build-for-testing | grep -E ^[1-9]{1}[0-9]*.[0-9]+ms | sort -n

formula_bump:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) swiftlint

bundle_install:
	bundle install

oss_scan: bundle_install
	bundle exec danger --verbose

pod_publish: bundle_install
	bundle exec pod trunk push SwiftLint.podspec

pod_lint: bundle_install
	bundle exec pod lib lint --verbose SwiftLint.podspec

docs: bundle_install
	swift run swiftlint generate-docs
	bundle exec jazzy

docs_linux: bundle_install
	bundle binstubs jazzy
	./bazel-bin/swiftlint generate-docs
	./bazel-bin/external/sourcekitten~/sourcekitten doc --spm --module-name SwiftLintCore > doc.json
	./bin/jazzy --sourcekitten-sourcefile doc.json

get_version:
	@echo "$(VERSION_STRING)"

%:
	@:
