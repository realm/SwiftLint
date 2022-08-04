import Foundation
import SourceKittenFramework

public struct StaticOperatorRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "static_operator",
        name: "Static Operator",
        description: "Operators should be declared as static functions, not free functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class A: Equatable {
              static func == (lhs: A, rhs: A) -> Bool {
                return false
              }
            """),
            Example("""
            class A<T>: Equatable {
                static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                    return false
                }
            """),
            Example("""
            public extension Array where Element == Rule {
              static func == (lhs: Array, rhs: Array) -> Bool {
                if lhs.count != rhs.count { return false }
                return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
              }
            }
            """),
            Example("""
            private extension Optional where Wrapped: Comparable {
              static func < (lhs: Optional, rhs: Optional) -> Bool {
                switch (lhs, rhs) {
                case let (lhs?, rhs?):
                  return lhs < rhs
                case (nil, _?):
                  return true
                default:
                  return false
                }
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓func == (lhs: A, rhs: A) -> Bool {
              return false
            }
            """),
            Example("""
            ↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
              return false
            }
            """),
            Example("""
            ↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
              if lhs.count != rhs.count { return false }
              return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
            }
            """),
            Example("""
            private ↓func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
              switch (lhs, rhs) {
              case let (lhs?, rhs?):
                return lhs < rhs
              case (nil, _?):
                return true
              default:
                return false
              }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .functionFree,
            let offset = dictionary.offset,
            let name = dictionary.name?.split(separator: "(").first.flatMap(String.init) else {
                return []
        }

        let characterSet = CharacterSet(charactersIn: name)
        guard characterSet.isDisjoint(with: .alphanumerics) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
