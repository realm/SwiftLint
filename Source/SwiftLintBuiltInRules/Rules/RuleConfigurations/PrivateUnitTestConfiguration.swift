import Foundation
import SwiftLintCore

struct PrivateUnitTestConfiguration: SeverityBasedRuleConfiguration, Equatable, CacheDescriptionProvider {
    typealias Parent = PrivateUnitTestRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "regex")
    private(set) var regex = SwiftLintCore.regex("XCTestCase")

    private(set) var name: String?
    private(set) var message = "Unit test marked `private` will not be run by XCTest."
    private(set) var included: NSRegularExpression?

    var cacheDescription: String {
        let jsonObject: [String] = [
            "private_unit_test",
            name ?? "",
            message,
            regex.pattern,
            included?.pattern ?? "",
            severityConfiguration.severity.rawValue
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
          let jsonString = String(data: jsonData, encoding: .utf8) {
              return jsonString
        }
        queuedFatalError("Could not serialize private unit test configuration for cache")
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        if let regexString = configurationDict["regex"] as? String {
            regex = try .cached(pattern: regexString)
        }
        if let includedString = configurationDict["included"] as? String {
            included = try .cached(pattern: includedString)
        }
        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
