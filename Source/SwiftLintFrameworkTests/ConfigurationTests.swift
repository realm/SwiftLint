//
//  ConfigurationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import SourceKittenFramework
import XCTest

class ConfigurationTests: XCTestCase {
    func testInit() {
        XCTAssert(Configuration(yaml: "") != nil,
            "initializing Configuration with empty YAML string should succeed")
        XCTAssert(Configuration(yaml: "a: 1\nb: 2") != nil,
            "initializing Configuration with valid YAML string should succeed")
        XCTAssert(Configuration(yaml: "|\na") == nil,
            "initializing Configuration with invalid YAML string should fail")
    }

    func testEmptyConfiguration() {
        guard let config = Configuration(yaml: "") else {
            XCTFail("empty YAML string should yield non-nil Configuration")
            return
        }
        XCTAssertEqual(config.disabledRules, [])
        XCTAssertEqual(config.included, [])
        XCTAssertEqual(config.excluded, [])
        XCTAssertEqual(config.reporter, "xcode")
        XCTAssertEqual(config.reporterFromString.identifier, "xcode")
    }

    func testDisabledRules() {
        let disabledConfig = Configuration(yaml: "disabled_rules:\n  - nesting\n  - todo")!
        XCTAssertEqual(disabledConfig.disabledRules,
            ["nesting", "todo"],
            "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Configuration.rulesFromYAML()
            .map({ $0.dynamicType.description.identifier })
            .filter({ !["nesting", "todo"].contains($0) })
        let configuredIdentifiers = disabledConfig.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)

        // Duplicate
        let duplicateConfig = Configuration( yaml: "disabled_rules:\n  - todo\n  - todo")
        XCTAssert(duplicateConfig == nil, "initializing Configuration with duplicate rules in " +
            " YAML string should fail")
    }

    func testDisabledRulesWithUnknownRule() {
        let validRule = "nesting"
        let bogusRule = "no_sprites_with_elf_shoes"
        let configuration = Configuration(yaml: "disabled_rules:\n" +
            "  - \(validRule)\n  - \(bogusRule)\n")!

        XCTAssertEqual(configuration.disabledRules,
            [validRule],
            "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Configuration.rulesFromYAML()
            .map({ $0.dynamicType.description.identifier })
            .filter({ ![validRule].contains($0) })
        let configuredIdentifiers = configuration.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    private class TestFileManager: NSFileManager {
        private override func filesToLintAtPath(path: String) -> [String] {
            switch path {
            case "directory": return ["directory/File1.swift", "directory/File2.swift",
                "directory/excluded/Excluded.swift",  "directory/ExcludedFile.swift"]
            case "directory/excluded" : return ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift" : return ["directory/ExcludedFile.swift"]
            default: break
            }
            XCTFail("Should not be called with path \(path)")
            return []
        }
    }

    func testExcludedPaths() {
        let configuration = Configuration(disabledRules: [], included: ["directory"],
            excluded: ["directory/excluded",  "directory/ExcludedFile.swift"],
            reporter: "json", rules: [])!
        let paths = configuration.lintablePathsForPath("", fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    // MARK: - Testing Configuration Equality

    private var projectMockConfig0: Configuration {
        var config = Configuration(path: projectMockYAML0, optional: false, silent: true)
        config.rootPath = projectMockPathLevel0
        return config
    }

    private var projectMockConfig2: Configuration {
        return Configuration(path: projectMockYAML2, optional: false, silent: true)
    }

    func testIsEqualTo() {
        XCTAssertEqual(projectMockConfig0, projectMockConfig0)
    }

    func testIsNotEqualTo() {
        XCTAssertNotEqual(projectMockConfig0, projectMockConfig2)
    }

    // MARK: - Testing Nested Configurations

    func testMerge() {
        XCTAssertEqual(projectMockConfig0.merge(projectMockConfig2), projectMockConfig2)
    }

    func testLevel0() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift0)!),
                       projectMockConfig0)
    }

    func testLevel1() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift1)!),
                       projectMockConfig0)
    }

    func testLevel2() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift2)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    func testLevel3() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift3)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    func testDoNotUseNestedConfigs() {
        var config = Configuration(yaml: "use_nested_configs: false\n")!
        config.rootPath = projectMockPathLevel0
        XCTAssertEqual(config.configForFile(File(path: projectMockSwift3)!),
                       config)
    }
}

// MARK: - ProjectMock Paths

extension XCTestCase {
    var bundlePath: String {
        return NSBundle(forClass: self.dynamicType).resourcePath!
    }

    var projectMockPathLevel0: String {
        return bundlePath.stringByAppendingPathComponent("ProjectMock")
    }

    var projectMockPathLevel1: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level1")
    }

    var projectMockPathLevel2: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level2")
    }

    var projectMockPathLevel3: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level3")
    }

    var projectMockYAML0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent(".swiftlint.yml")
    }

    var projectMockYAML2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent(".swiftlint.yml")
    }

    var projectMockSwift0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level0.swift")
    }

    var projectMockSwift1: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level1.swift")
    }

    var projectMockSwift2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level2.swift")
    }

    var projectMockSwift3: String {
        return projectMockPathLevel3.stringByAppendingPathComponent("Level3.swift")
    }
}
