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
            Example("var url = URL()"),
            Example("var url: CustomStringConvertible = URL()"),
            Example("@IBInspectable var color: UIColor = UIColor.white")
        ],
        triggeringExamples: [
            Example("var url↓:URL=URL()"),
            Example("var url↓:URL = URL(string: \"\")"),
            Example("var url↓: URL = URL()"),
            Example("let url↓: URL = URL()"),
            Example("lazy var url↓: URL = URL()"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """)
        ],
        corrections: [
            Example("var url↓: URL = URL()"): Example("var url = URL()"),
            Example("let url↓: URL = URL()"): Example("let url = URL()"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"):
                Example("let alphanumerics = CharacterSet.alphanumerics"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """):
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar = Int(5)
              }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let typeAnnotationPattern = ":\\s?\\w+"
        let pattern = "(var|let)\\s?\\w+\(typeAnnotationPattern)\\s?=\\s?\\w+(\\(|.)"
        let foundRanges = file.match(pattern: pattern, with: [.keyword, .identifier, .typeidentifier, .identifier])
        return foundRanges
            .filter { !isFalsePositive(in: file, range: $0) && !isIBInspectable(range: $0, file: file) }
            .compactMap {
                file.match(pattern: typeAnnotationPattern,
                           excludingSyntaxKinds: SyntaxKind.commentAndStringKinds, range: $0).first
            }
    }

    private func isFalsePositive(in file: SwiftLintFile, range: NSRange) -> Bool {
        let substring = file.stringView.substring(with: range)

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

    private func isIBInspectable(range: NSRange, file: SwiftLintFile) -> Bool {
        guard let byteRange = file.stringView.NSRangeToByteRange(start: range.location, length: range.length),
            let dict = file.structureDictionary.structures(forByteOffset: byteRange.location).last,
            let kind = dict.declarationKind,
            SwiftDeclarationKind.variableKinds.contains(kind) else {
                return false
        }

        return dict.enclosedSwiftAttributes.contains(.ibinspectable)
    }
}
