import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class RemoteRuleResolverTests: XCTestCase {
    func testCreatesRemoteRule() throws {
        let ruleDescription = RuleDescription(identifier: "test", name: "Test", description: "Test", kind: .lint)
        let pluginDescription = PluginDescription(ruleDescription: ruleDescription, requiredInformation: [.structure])

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let jsonString = String(decoding: try encoder.encode(pluginDescription), as: UTF8.self)
        let scriptContent = """
                            #!/bin/bash
                            echo '\(jsonString)'
                            """
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try scriptContent.data(using: .utf8)!.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: url.path)

        let ruleConfiguration =  [
            "k1": "v1",
            "k2": 2
        ] as [String: Any]
        let configuration = [
            "foo": 20,
            "test": ruleConfiguration
        ] as [String: Any]

        let resolver = RemoteRuleResolver()
        let remoteRule = try resolver.remoteRule(forExecutable: url.path,
                                                 configuration: configuration)

        XCTAssertEqual(remoteRule.ruleDescription.identifier, "test")
        XCTAssertEqual(remoteRule.description.requiredInformation, [.structure])

        XCTAssertEqual(remoteRule.configuration as? NSDictionary, ruleConfiguration.bridge())
    }
}
