import Foundation
@testable import SwiftLintFramework
import XCTest

extension ConfigurationTests {
    // MARK: - Methods: Tests
    func testValidChildConfig() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath

        for path in [projectMockPathChildConfigValid1, projectMockPathChildConfigValid2] {
            FileManager.default.changeCurrentDirectoryPath(path)

            assertEqual(
                Configuration(
                    configurationFiles: ["child_config_main.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                ),
                Configuration(
                    configurationFiles: ["child_config_expected.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                )
            )
        }

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    func testValidParentConfig() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath

        for path in [projectMockPathParentConfigValid1, projectMockPathParentConfigValid2] {
            FileManager.default.changeCurrentDirectoryPath(path)

            assertEqual(
                Configuration(
                    configurationFiles: ["parent_config_main.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                ),
                Configuration(
                    configurationFiles: ["parent_config_expected.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                )
            )
        }

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    func testCommandLineChildConfigs() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath

        for path in [projectMockPathChildConfigValid1, projectMockPathChildConfigValid2] {
            FileManager.default.changeCurrentDirectoryPath(path)

            assertEqual(
                Configuration(
                    configurationFiles: ["child_config_main.yml", "child_config_child1.yml", "child_config_child2.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                ),
                Configuration(
                    configurationFiles: ["child_config_expected.yml"],
                    rootPath: path,
                    optional: false,
                    quiet: true
                )
            )
        }

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    // MARK: Helpers
    private func assertEqual(_ configuration1: Configuration, _ configuration2: Configuration) {
        XCTAssertEqual(
            configuration1.rulesWrapper.disabledRuleIdentifiers,
            configuration2.rulesWrapper.disabledRuleIdentifiers
        )

        XCTAssertEqual(
            configuration1.rules.map { type(of: $0).description.identifier },
            configuration2.rules.map { type(of: $0).description.identifier }
        )

        XCTAssertEqual(
            Set(configuration1.rulesWrapper.allRulesWrapped.map { $0.rule.configurationDescription }),
            Set(configuration2.rulesWrapper.allRulesWrapped.map { $0.rule.configurationDescription })
        )

        XCTAssertEqual(
            Set(configuration1.includedPaths),
            Set(configuration2.includedPaths)
        )

        XCTAssertEqual(
            Set(configuration1.excludedPaths),
            Set(configuration2.excludedPaths)
        )
    }
}
