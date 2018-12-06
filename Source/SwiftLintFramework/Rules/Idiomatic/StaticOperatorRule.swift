import Foundation
import SourceKittenFramework

public struct StaticOperatorRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "static_operator",
        name: "Static Operator",
        description: "Operators should be declared as static functions, not free functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            class A: Equatable {
              static func == (lhs: A, rhs: A) -> Bool {
                return false
              }
            """,
            """
            class A<T>: Equatable {
                static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                    return false
                }
            """,
            """
            public extension Array where Element == Rule {
              static func == (lhs: Array, rhs: Array) -> Bool {
                if lhs.count != rhs.count { return false }
                return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
              }
            }
            """,
            """
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
            """
        ],
        triggeringExamples: [
            """
            ↓func == (lhs: A, rhs: A) -> Bool {
              return false
            }
            """,
            """
            ↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
              return false
            }
            """,
            """
            ↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
              if lhs.count != rhs.count { return false }
              return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
            }
            """,
            """
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
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
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
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
