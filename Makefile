TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-workspace 'SwiftLint.xcworkspace' \
	-scheme 'swiftlint' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/swiftlint.app
SWIFTLINTFRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/SwiftLintFramework.framework
SWIFTLINT_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/swiftlint
XCTEST_LOCATION=.build/debug/SwiftLintPackageTests.xctest

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin
LICENSE_PATH="$(shell pwd)/LICENSE"

OUTPUT_PACKAGE=SwiftLint.pkg

COMPONENTS_PLIST=Source/swiftlint/Supporting Files/Components.plist
SWIFTLINT_PLIST=Source/swiftlint/Supporting Files/Info.plist
SWIFTLINTFRAMEWORK_PLIST=Source/SwiftLintFramework/Supporting Files/Info.plist

VERSION_STRING=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(SWIFTLINT_PLIST)")

.PHONY: all bootstrap clean install package test uninstall

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build

sourcery:
	sourcery --sources Tests --templates .sourcery/LinuxMain.stencil --output .sourcery
	sed -e 4,11d .sourcery/LinuxMain.generated.swift > .sourcery/LinuxMain.swift
	sed -n 4,10p .sourcery/LinuxMain.generated.swift | cat - .sourcery/LinuxMain.swift > Tests/LinuxMain.swift
	rm .sourcery/LinuxMain.swift .sourcery/LinuxMain.generated.swift
	sourcery --sources Source/SwiftLintFramework/Rules --templates .sourcery/MasterRuleList.stencil --output .sourcery
	sed -e 4,11d .sourcery/MasterRuleList.generated.swift > .sourcery/MasterRuleList.swift
	sed -n 4,10p .sourcery/MasterRuleList.generated.swift | cat - .sourcery/MasterRuleList.swift > Source/SwiftLintFramework/Models/MasterRuleList.swift
	rm .sourcery/MasterRuleList.swift .sourcery/MasterRuleList.generated.swift

bootstrap:
	script/bootstrap

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Debug clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Release clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

install: uninstall package
	sudo installer -pkg SwiftLint.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	rm -f "$(BINARIES_FOLDER)/swiftlint"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Release install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(SWIFTLINTFRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	mv -f "$(SWIFTLINT_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint"
	rm -rf "$(BUILT_BUNDLE)"
	install_name_tool -delete_rpath "@executable_path/../Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -Rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint" "$(PREFIX)/bin/"
	install_name_tool -rpath "/Library/Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks" "@executable_path/../Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks" "$(PREFIX)/bin/swiftlint"
	install_name_tool -rpath "/Library/Frameworks" "@executable_path/../Frameworks" "$(PREFIX)/bin/swiftlint"

portable_zip: installables
	cp -Rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework" "$(TEMPORARY_FOLDER)"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint" "$(TEMPORARY_FOLDER)"
	install_name_tool -rpath "/Library/Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks" "@executable_path/SwiftLintFramework.framework/Versions/Current/Frameworks" "$(TEMPORARY_FOLDER)/swiftlint"
	install_name_tool -rpath "/Library/Frameworks" "@executable_path" "$(TEMPORARY_FOLDER)/swiftlint"
	rm -f "./portable_swiftlint.zip"
	cp -f "$(LICENSE_PATH)" "$(TEMPORARY_FOLDER)"
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "swiftlint" "SwiftLintFramework.framework" "LICENSE") > "./portable_swiftlint.zip"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "io.realm.swiftlint" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

archive:
	carthage build --no-skip-current --platform mac
	carthage archive SwiftLintFramework

release: package archive portable_zip

docker_test:
	if [ -d $(XCTEST_LOCATION) ]; then rm -rf $(XCTEST_LOCATION); fi
	docker run -v `pwd`:`pwd` -w `pwd` --name swiftlint --rm norionomura/sourcekit:311 swift test

docker_htop:
	docker run -it --rm --pid=container:swiftlint terencewestphal/htop || reset

# http://irace.me/swift-profiling/
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build-for-testing | grep -E ^[1-9]{1}[0-9]*.[0-9]+ms | sort -n

publish:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) swiftlint
	pod trunk push SwiftLintFramework.podspec
	pod trunk push SwiftLint.podspec

get_version:
	@echo $(VERSION_STRING)

push_version:
	$(eval NEW_VERSION_AND_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval NEW_VERSION := $(shell echo $(NEW_VERSION_AND_NAME) | sed 's/:.*//' ))
	@sed -i '' 's/## Master/## $(NEW_VERSION_AND_NAME)/g' CHANGELOG.md
	@sed 's/__VERSION__/$(NEW_VERSION)/g' script/Version.swift.template > Source/SwiftLintFramework/Models/Version.swift
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(NEW_VERSION)" "$(SWIFTLINTFRAMEWORK_PLIST)"
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(NEW_VERSION)" "$(SWIFTLINT_PLIST)"
	git commit -a -m "release $(NEW_VERSION)"
	git tag -a $(NEW_VERSION) -m "$(NEW_VERSION_AND_NAME)"
	git push origin master
	git push origin $(NEW_VERSION)

%:
	@:
