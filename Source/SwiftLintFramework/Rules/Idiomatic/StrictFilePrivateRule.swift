import Foundation
import SourceKittenFramework

public struct StrictFilePrivateRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strict_fileprivate",
        name: "Strict fileprivate",
        description: "`fileprivate` should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "private extension String {}",
            """
            public
            extension String {}
            """,
            """
            open extension
              String {}
            """,
            "internal extension String {}"
        ],
        triggeringExamples: [
            "↓fileprivate extension String {}",
            """
            ↓fileprivate
              extension String {}
            """,
            """
            ↓fileprivate extension
              String {}
            """,
            """
            extension String {
              ↓fileprivate func Something(){}
            }
            """,
            """
            class MyClass {
              ↓fileprivate let myInt = 4
            }
            """,
            """
            class MyClass {
              ↓fileprivate(set) var myInt = 4
            }
            """,
            """
            struct Outter {
              struct Inter {
                ↓fileprivate struct Inner {}
              }
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        // Mark all fileprivate occurences as a violation
        return file.match(pattern: "fileprivate", with: [.attributeBuiltin]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
