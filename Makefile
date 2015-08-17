TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-workspace 'SwiftLint.xcworkspace' -scheme 'swiftlint' DSTROOT=$(TEMPORARY_FOLDER)

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/swiftlint.app
SWIFTLINTFRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/SwiftLintFramework.framework
SWIFTLINT_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/swiftlint

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=SwiftLint.pkg

VERSION_STRING=$(shell agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=Source/swiftlint/Components.plist

.PHONY: all bootstrap clean install package test uninstall

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build

bootstrap:
	script/bootstrap

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg SwiftLint.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	rm -rf "$(FRAMEWORKS_FOLDER)/SourceKittenFramework.framework"
	rm -f "$(BINARIES_FOLDER)/swiftlint"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(SWIFTLINTFRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	mv -f "$(SWIFTLINT_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/swiftlint" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks/"  "$(PREFIX)/bin/swiftlint"
	install_name_tool -add_rpath "@executable_path/../Frameworks/SwiftLintFramework.framework/Versions/Current/Frameworks/SourceKittenFramework.framework/Versions/Current/Frameworks/"  "$(PREFIX)/bin/swiftlint"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "io.realm.swiftlint" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
