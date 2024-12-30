import Foundation
import SwiftLintFramework
import TestHelpers
import XCTest

private let config: Configuration = {
    let bazelWorkspaceDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
    let rootProjectDirectory = bazelWorkspaceDirectory ?? #filePath.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent
    _ = FileManager.default.changeCurrentDirectoryPath(rootProjectDirectory)
    return Configuration(configurationFiles: [Configuration.defaultFileName])
}()

final class IntegrationTests: SwiftLintTestCase {
    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeByPrefix: false)
        XCTAssert(
            swiftFiles.contains(where: { #filePath.bridge().absolutePathRepresentation() == $0.path }),
            "current file should be included"
        )

        let storage = RuleStorage()
        let violations = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config).collect(into: storage).styleViolations(using: storage)
        }
        violations.forEach { violation in
            violation.location.file!.withStaticString {
                XCTFail(violation.reason, file: $0, line: UInt(violation.location.line!))
            }
        }
    }

    func testSwiftLintAutoCorrects() {
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeByPrefix: false)
        let storage = RuleStorage()
        let corrections = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config).collect(into: storage).correct(using: storage)
        }
        for correction in corrections {
            correction.location.file!.withStaticString {
                XCTFail(correction.ruleDescription.description,
                        file: $0, line: UInt(correction.location.line!))
            }
        }
    }

    func testDefaultConfigurations() {
        let defaultConfig = Configuration(rulesMode: .allCommandLine).rules
            .map { type(of: $0) }
            .filter { $0.identifier != "custom_rules" }
            .map { ruleType in
                let rule = ruleType.init()
                return """
                    \(ruleType.identifier):
                    \(rule.createConfigurationDescription().yaml().indent(by: 2))
                      meta:
                        opt-in: \(rule is any OptInRule)
                    """
            }
            .joined(separator: "\n")
        let referenceFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("default_rule_configurations.yml")
        XCTAssertEqual(defaultConfig + "\n", try String(contentsOf: referenceFile))
    }
}

private struct StaticStringImitator {
    let string: String

    func withStaticString(_ closure: (StaticString) -> Void) {
        let isASCII = string.utf8.allSatisfy { $0 < 0x7f }
        string.utf8CString.dropLast().withUnsafeBytes {
            let imitator = Imitator(startPtr: $0.baseAddress!, utf8CodeUnitCount: $0.count, isASCII: isASCII)
            closure(imitator.staticString)
        }
    }

    struct Imitator {
        let startPtr: UnsafeRawPointer
        let utf8CodeUnitCount: Int
        let flags: Int8

        init(startPtr: UnsafeRawPointer, utf8CodeUnitCount: Int, isASCII: Bool) {
            self.startPtr = startPtr
            self.utf8CodeUnitCount = utf8CodeUnitCount
            flags = isASCII ? 0x2 : 0x0
        }

        var staticString: StaticString {
            unsafeBitCast(self, to: StaticString.self)
        }
    }
}

private extension String {
    func withStaticString(_ closure: (StaticString) -> Void) {
        StaticStringImitator(string: self).withStaticString(closure)
    }
}
