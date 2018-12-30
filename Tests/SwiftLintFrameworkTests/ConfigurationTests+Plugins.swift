@testable import SwiftLintFramework
import XCTest

extension ConfigurationTests {
    func testLoadsPlugins() {
        let configurationJSON = ["plugins": ["path/to/plugin"]]
        let resolver = ResolverMock()
        let configuration = Configuration(dict: configurationJSON, remoteRulesResolver: resolver)!

        XCTAssertEqual(configuration.plugins, ["path/to/plugin"])
        XCTAssertEqual(configuration.remoteRules.map { $0.description.identifier }, ["test"])
        XCTAssertEqual(resolver.executable, "path/to/plugin")
        XCTAssertEqual(resolver.configuration as? [String: [String]], configurationJSON)
    }
}

private class ResolverMock: RemoteRuleResolverProtocol {
    private(set) var executable: String?
    private(set) var configuration: [String: Any]?

    func remoteRule(forExecutable executable: String, configuration: [String: Any]?) throws -> RemoteRule {
        self.executable = executable
        self.configuration = configuration

        let description = RuleDescription(identifier: "test", name: "Test", description: "", kind: .idiomatic)
        return RemoteRule(description: description, executable: executable, configuration: nil)
    }
}
