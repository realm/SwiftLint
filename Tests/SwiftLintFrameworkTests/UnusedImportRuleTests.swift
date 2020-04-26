@testable import SwiftLintFramework
import XCTest

class UnusedImportRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(UnusedImportRule.description)
    }

    func testWithAllowedTransitiveImports() {
        let nonTriggeringExamples = [
            Example("""
            import Foundation
            typealias Foo = CFData
            """, testOnLinux: false),
            Example("""
            import Foundation
            typealias Foo = CFData
            @objc
            class A {}
            """, testOnLinux: false)
        ]

        let triggeringExamples = [
            Example("""
            import Foundation
            typealias Foo = UIView
            """, testOnLinux: false)
        ]

        let description = UnusedImportRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(
            description,
            ruleConfiguration: [
                "require_explicit_imports": true,
                "allowed_transitive_imports": [
                    [
                        "module": "Foundation",
                        "allowed_transitive_imports": ["CoreFoundation"]
                    ]
                ]
            ]
        )
    }
}
