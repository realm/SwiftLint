import SwiftLintFramework
import XCTest

 class MissingDocsRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(MissingDocsRule.description)
    }

    func testWithExcludesExtensionsDisabled() {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = MissingDocsRule.description
        let triggeringComments = [
            Example("""
            public extension A {}
            """
            )
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description,
                   ruleConfiguration: ["excludes_extensions": false])
    }

    func testWithExcludesInheritedTypesDisabled() {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = MissingDocsRule.description
        let triggeringComments = [
            // locally-defined superclass member is documented, but subclass member is not
            Example("""
            /// docs
            public class A {
            /// docs
            public func b() {}
            }
            // no docs
            public class B: A { override public func b() {} }
            """),
            // externally-defined superclass member is documented, but subclass member is not
            Example("""
            import Foundation
            // no docs
            public class B: NSObject {
            // no docs
            override public var description: String { fatalError() } }
            """)
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description,
                   ruleConfiguration: ["excludes_inherited_types": false])
    }
 }
