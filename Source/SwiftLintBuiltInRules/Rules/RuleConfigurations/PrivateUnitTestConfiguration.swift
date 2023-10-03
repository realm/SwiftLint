import Foundation
import SwiftLintCore

struct PrivateUnitTestConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = PrivateUnitTestRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "test_parent_classes")
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    @ConfigurationElement(key: "regex")
    private(set) var regex: RegularExpression = "XCTestCase"

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        if let extraTestParentClasses = configurationDict[$testParentClasses.key] as? [String] {
            self.testParentClasses.formUnion(extraTestParentClasses)
        }
        if let regexString = configurationDict[$regex.key] as? String {
            // TODO: [01/09/2025] Remove deprecation warning after ~2 years and use `UnitTestConfiguration`
            // instead of this configuration.
            queuedPrintError(
                """
                warning: '\($regex.key)' has been replaced by a list of explicit parent class names. They can be \
                configured in the '\($testParentClasses.key)' option. '\($regex.key)' will be completely removed \
                in a future release.
                """
            )
            regex = try RegularExpression(pattern: regexString)
        }
        if configurationDict["included"] is String {
            // TODO: [01/09/2025] Remove deprecation warning after ~2 years and replace this configuration by
            // `UnitTestConfiguration`.
            queuedPrintError(
                "warning: 'included' is ignored from now on. You may remove it from the configuration file."
            )
        }
        if configurationDict["name"] is String {
            // TODO: [01/09/2025] Remove deprecation warning after ~2 years and replace this configuration by
            // `UnitTestConfiguration`.
            queuedPrintError(
                "warning: 'name' is ignored from now on. You may remove it from the configuration file."
            )
        }
        if configurationDict["message"] is String {
            // TODO: [01/09/2025] Remove deprecation warning after ~2 years and replace this configuration by
            // `UnitTestConfiguration`.
            queuedPrintError(
                "warning: 'message' is ignored from now on. You may remove it from the configuration file."
            )
        }
        if let severityString = configurationDict[$severityConfiguration.key] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
