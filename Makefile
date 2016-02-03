TEMPORARY_FOLDER?=/tmp/SwiftLint.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-xcconfig settings-for-all-projects.xcconfig -workspace 'SwiftLint.xcworkspace' -scheme 'swiftlint' DSTROOT=$(TEMPORARY_FOLDER)

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/swiftlint.app
SWIFTLINTFRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/SwiftLintFramework.framework
SWIFTLINT_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/swiftlint

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=SwiftLint.pkg

VERSION_STRING=$(shell agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=Source/swiftlint/Supporting Files/Components.plist

SWIFT_SNAPSHOT=swift-DEVELOPMENT-SNAPSHOT-2016-01-25-a

SPM=/Library/Developer/Toolchains/$(SWIFT_SNAPSHOT).xctoolchain/usr/bin/swift build
SPM_INCLUDE=/Library/Developer/Toolchains/$(SWIFT_SNAPSHOT).xctoolchain/usr/local/include
SPM_LIB=/Library/Developer/Toolchains/$(SWIFT_SNAPSHOT).xctoolchain/usr/lib

SPMFLAGS=--configuration debug
# for including "clang-c"
SPMFLAGS+=-Xcc -ISource/Clang_C -Xcc -I$(SPM_INCLUDE)
# for linking sourcekitd and clang-c
SPMFLAGS+= -Xcc -F$(SPM_LIB) -Xlinker -F$(SPM_LIB) -Xlinker -L$(SPM_LIB)
# for loading sourcekitd and clang-c
SPMFLAGS+= -Xlinker -rpath -Xlinker $(SPM_LIB)

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

install: uninstall package
	sudo installer -pkg SwiftLint.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SwiftLintFramework.framework"
	rm -f "$(BINARIES_FOLDER)/swiftlint"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

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

release: package archive

# http://irace.me/swift-profiling/
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build test | grep -E ^[1-9]{1}[0-9]*.[0-9]ms | sort -n

swift_snapshot_install:
	curl https://swift.org/builds/development/xcode/$(SWIFT_SNAPSHOT)/$(SWIFT_SNAPSHOT)-osx.pkg -o swift.pkg
	sudo installer -pkg swift.pkg -target /

spm:
	sed -i "" "s/swift-latest/$(SWIFT_SNAPSHOT)/" Source/Clang_C/module.modulemap
	$(SPM) $(SPMFLAGS) || (\
		echo "SPM does not use Package.swift. So now removing unnecesory directories in 'Packages/*' that cause build error.";\
		rm -rf Packages/SourceKitten-*/Source/sourcekitten;\
		rm -rf Packages/SourceKitten-*/Source/SourceKittenFrameworkTests;\
		rm -rf Packages/YamlSwift-*/YamlTests;\
		echo "Runs SPM again.";\
	) && $(SPM) $(SPMFLAGS)
	sed -i "" "s/$(SWIFT_SNAPSHOT)/swift-latest/" Source/Clang_C/module.modulemap

spm_test: spm
	.build/Debug/SwiftLintFrameworkTests

spm_clean:
	$(SPM) --clean

spm_clean_dist:
	$(SPM) --clean=dist
