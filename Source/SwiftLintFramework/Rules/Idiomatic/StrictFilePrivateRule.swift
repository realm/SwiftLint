import Foundation
import SourceKittenFramework

public struct StrictFilePrivateRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strict_fileprivate",
        name: "Strict fileprivate",
        description: "`fileprivate` should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("""
            public
            extension String {}
            """),
            Example("""
            open extension
              String {}
            """),
            Example("internal extension String {}")
        ],
        triggeringExamples: [
            Example("↓fileprivate extension String {}"),
            Example("""
            ↓fileprivate
              extension String {}
            """),
            Example("""
            ↓fileprivate extension
              String {}
            """),
            Example("""
            extension String {
              ↓fileprivate func Something(){}
            }
            """),
            Example("""
            class MyClass {
              ↓fileprivate let myInt = 4
            }
            """),
            Example("""
            class MyClass {
              ↓fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            struct Outter {
              struct Inter {
                ↓fileprivate struct Inner {}
              }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        // Mark all fileprivate occurrences as a violation
        return file.match(pattern: "fileprivate", with: [.attributeBuiltin]).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
