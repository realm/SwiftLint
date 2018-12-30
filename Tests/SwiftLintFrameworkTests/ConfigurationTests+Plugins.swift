@testable import SwiftLintFramework
import XCTest

extension ConfigurationTests {
    func testLoadsPlugins() {
        let configurationJSON = ["plugins": ["path/to/plugin"], "test": 10] as [String: Any]
        let resolver = ResolverMock()
        let configuration = Configuration(dict: configurationJSON, remoteRulesResolver: resolver)!

        XCTAssertEqual(configuration.plugins, ["path/to/plugin"])
        XCTAssertEqual(configuration.remoteRules.map { $0.description.identifier }, ["test"])
        XCTAssertEqual(resolver.executable, "path/to/plugin")
        XCTAssertEqual(resolver.configuration?.bridge(), configurationJSON.bridge())
    }

    func testEnableAllRulesConfigurationWithPlugins() {
        let configuration = Configuration(dict: ["plugins": ["path/to/plugin", "path/to/mock"]],
                                          ruleList: masterRuleList,
                                          enableAllRules: true, cachePath: nil,
                                          remoteRulesResolver: ResolverMock())!
        XCTAssertEqual(configuration.rules.count, masterRuleList.list.count)
        XCTAssertEqual(configuration.remoteRules.count, 2)
    }

    func testWhitelistRulesWithPlugins() {
        let config = Configuration(dict: ["whitelist_rules": ["nesting", "test"],
                                          "plugins": ["path/to/plugin",
                                                      "path/to/mock"]],
                                   remoteRulesResolver: ResolverMock())!
        let configuredIdentifiers = config.rules.map {
            type(of: $0).description.identifier
        }.sorted()

        XCTAssertEqual(["nesting"], configuredIdentifiers)
        XCTAssertEqual(["test"], config.remoteRules.map { $0.description.identifier })
    }

    func testDisabledRulesWithPlugins() {
        let resolver = ResolverMock()
        let disabledConfig = Configuration(dict: ["disabled_rules": ["nesting", "test"],
                                                  "plugins": ["path/to/plugin",
                                                              "path/to/mock"]],
                                           remoteRulesResolver: resolver)!
        XCTAssertEqual(disabledConfig.disabledRules, ["nesting"])
        let expectedIdentifiers = Set(masterRuleList.list.keys
            .filter({ !(["nesting" ] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(disabledConfig.rules.map {
            type(of: $0).description.identifier
        })

        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
        XCTAssertEqual(disabledConfig.remoteRules.identifiers, ["mock"])
    }
}

private class ResolverMock: RemoteRuleResolverProtocol {
    private(set) var executable: String?
    private(set) var configuration: [String: Any]?

    private let identifiers = ["path/to/plugin": "test",
                               "path/to/mock": "mock"]

    func remoteRule(forExecutable executable: String, configuration: [String: Any]?) throws -> RemoteRule {
        self.executable = executable
        self.configuration = configuration

        let identifier = identifiers[executable] ?? ""
        let description = RuleDescription(identifier: identifier, name: "Test", description: "", kind: .idiomatic)
        return RemoteRule(description: description, executable: executable, configuration: nil)
    }
}
