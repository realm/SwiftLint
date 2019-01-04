import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class RemoteRuleTests: XCTestCase {
    func testValidate() throws {
        let ruleDescription = RuleDescription(identifier: "test", name: "Test", description: "Test", kind: .lint)
        let pluginDescription = PluginDescription(ruleDescription: ruleDescription, requiredInformation: [.structure])
        let configuration = ["key": "value"]
        let fileContents = "let x = 10"

        let server = RemoteLintServer(socketPath: "/tmp/test.socket")
        let delegate = MockRemoteLintServerDelegate()
        delegate.violationsToReturn = [
            StyleViolation(ruleDescription: ruleDescription, severity: .error,
                           location: Location(file: nil, line: 1, character: 4),
                           reason: "Test violation")
        ]

        server.delegate = delegate
        server.run()

        // wait until the server has started
        while !delegate.startedListening {}

        let remoteRule = RemoteRule(description: pluginDescription, configuration: configuration)
        let violations = remoteRule.validate(file: File(contents: fileContents))

        XCTAssertEqual(violations, delegate.violationsToReturn)
        XCTAssertEqual(delegate.payload?.contents.value, fileContents)
        XCTAssertNil(delegate.payload!.path)
        XCTAssertTrue(delegate.payload!.syntaxMap.value.isEmpty)
        XCTAssertFalse(delegate.payload!.structure.value.isEmpty)
        XCTAssertEqual(delegate.payload!.configuration as? [String: String], configuration)

        server.shutdown()
    }
}

private class MockRemoteLintServerDelegate: RemoteLintServerDelegate {
    var payload: RemoteRulePayload?
    var violationsToReturn: [StyleViolation] = []
    var startedListening = false

    func server(_ server: RemoteLintServer, didReceivePayload payload: RemoteRulePayload) -> [StyleViolation] {
        self.payload = payload
        return violationsToReturn
    }

    func serverStartedListening(_ server: RemoteLintServer) {
        startedListening = true
    }
}
