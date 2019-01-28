import Foundation
import SourceKittenFramework

public struct RedundantTypeAnnotationRule: OptInRule, SubstitutionCorrectableRule,
                                           ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "var url = URL()",
            "var url: CustomStringConvertible = URL()"
        ],
        triggeringExamples: [
            "var url↓:URL=URL()",
            "var url↓:URL = URL(string: \"\")",
            "var url↓: URL = URL()",
            "let url↓: URL = URL()",
            "lazy var url↓: URL = URL()",
            "let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics",
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """
        ],
        corrections: [
            "var url↓: URL = URL()": "var url = URL()",
            "let url↓: URL = URL()": "let url = URL()",
            "let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics":
                "let alphanumerics = CharacterSet.alphanumerics",
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """:
            """
            class ViewController: UIViewController {
              func someMethod() {
                let myVar = Int(5)
              }
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "")
    }

    public func violationRanges(in file: File) -> [NSRange] {
        let typeAnnotationPattern = ":\\s?\\w+"
        let pattern = "(var|let)\\s?\\w+\(typeAnnotationPattern)\\s?=\\s?\\w+(\\(|.)"
        let foundRanges = file.match(pattern: pattern, with: [.keyword, .identifier, .typeidentifier, .identifier])
        return foundRanges
            .filter { !isFalsePositive(in: file, range: $0) }
            .compactMap {
                file.match(pattern: typeAnnotationPattern,
                           excludingSyntaxKinds: SyntaxKind.commentAndStringKinds, range: $0).first
            }
    }

    private func isFalsePositive(in file: File, range: NSRange) -> Bool {
        let substring = file.contents.bridge().substring(with: range)

        let components = substring.components(separatedBy: "=")
        let charactersToTrimFromRhs = CharacterSet(charactersIn: ".(").union(.whitespaces)

        guard
            components.count == 2,
            let lhsTypeName = components[0].components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        else {
            return true
        }

        let rhsTypeName = components[1].trimmingCharacters(in: charactersToTrimFromRhs)
        return lhsTypeName != rhsTypeName
    }
}
