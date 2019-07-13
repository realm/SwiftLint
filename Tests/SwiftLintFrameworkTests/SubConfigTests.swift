import Foundation
@testable import SwiftLintFramework
import XCTest

class SubConfigTests: XCTestCase, ProjectMock {
    // MARK: - Methods
    func testValidSubConfig() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath

        for path in [projectMockPathSubConfigValid1, projectMockPathSubConfigValid2] {
            FileManager.default.changeCurrentDirectoryPath(path)
            let config = Configuration(
                path: "sub_config_main.yml",
                rootPath: path,
                optional: false,
                quiet: true
            )

            let expectedConfig = Configuration(
                path: "sub_config_expected.yml",
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
                Set(config.included),
                Set(expectedConfig.included)
            )
            XCTAssertEqual(
                Set(config.excluded),
                Set(expectedConfig.excluded)
            )
        }

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }
}
