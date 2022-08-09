import Foundation
import SourceKittenFramework

public struct PreferSelfTypeOverTypeOfSelfRule: OptInRule, ConfigurationProviderRule, SubstitutionCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "prefer_self_type_over_type_of_self",
        name: "Prefer Self Type Over Type of Self",
        description: "Prefer `Self` over `type(of: self)` when accessing properties or calling methods.",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            class Foo {
                func bar() {
                    Self.baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """),
            Example("""
            class A {
                func foo(param: B) {
                    type(of: param).bar()
                }
            }
            """),
            Example("""
            class A {
                func foo() {
                    print(type(of: self))
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo {
                func bar() {
                    ↓type(of: self).baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓type(of: self).baz)
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓Swift.type(of: self).baz)
                }
            }
            """)
        ],
        corrections: [
            Example("""
            class Foo {
                func bar() {
                    ↓type(of: self).baz()
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    Self.baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓type(of: self).baz)
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓Swift.type(of: self).baz)
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """)
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = "((?:Swift\\s*\\.\\s*)?type\\(\\s*of\\:\\s*self\\s*\\))\\s*\\."
        return file.matchesAndSyntaxKinds(matching: pattern)
            .filter {
                $0.1 == [.identifier, .identifier, .identifier, .keyword] ||
                $0.1 == [.identifier, .identifier, .keyword]
            }
            .map { $0.0.range(at: 1) }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "Self")
    }
}
