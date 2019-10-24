import Foundation
@testable import SwiftLintFramework
import XCTest

class ChildConfigTests: XCTestCase, ProjectMock {
    // MARK: - Methods
    func testValidChildConfig() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath

        for path in [projectMockPathChildConfigValid1, projectMockPathChildConfigValid2] {
            FileManager.default.changeCurrentDirectoryPath(path)
            let config = Configuration(
                configurationFiles: ["child_config_main.yml"],
                rootPath: path,
                optional: false,
                quiet: true
            )

            let expectedConfig = Configuration(
                configurationFiles: ["child_config_expected.yml"],
                rootPath: path,
                optional: false,
                quiet: true
            )

            XCTAssertEqual(
                config.rulesStorage.disabledRuleIdentifiers,
                expectedConfig.rulesStorage.disabledRuleIdentifiers
            )
            XCTAssertEqual(
                config.rules.map { type(of: $0).description.identifier },
                expectedConfig.rules.map { type(of: $0).description.identifier }
            )

            XCTAssertEqual(
                Set(config.rulesStorage.allRulesWithConfigurations.map { $0.configurationDescription }),
                Set(expectedConfig.rulesStorage.allRulesWithConfigurations.map { $0.configurationDescription })
            )
            XCTAssertEqual(
                Set(config.includedPaths),
                Set(expectedConfig.includedPaths)
            )
            XCTAssertEqual(
                Set(config.excludedPaths),
                Set(expectedConfig.excludedPaths)
            )
        }

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }
}
