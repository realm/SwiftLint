import Foundation
import SourceKittenFramework

struct RedundantTypeAnnotationRule: OptInRule, SubstitutionCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var url = URL()"),
            Example("var url: CustomStringConvertible = URL()"),
            Example("@IBInspectable var color: UIColor = UIColor.white"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction: Direction = .up
            """),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction = Direction.up
            """)
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
            """),
            Example("var isEnabled↓: Bool = true"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction↓: Direction = Direction.up
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

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    private let typeAnnotationPattern: String
    private let expressionPattern: String

    init() {
        typeAnnotationPattern =
            ":\\s*" + // semicolon and any number of whitespaces
            "\\w+"    // type name

        expressionPattern =
            "(var|let)" + // var or let
            "\\s+" +      // at least single whitespace
            "\\w+" +      // variable name
            "\\s*" +      // possible whitespaces
            typeAnnotationPattern +
            "\\s*=\\s*" + // assignment operator with possible surrounding whitespaces
            "\\w+" +      // assignee name (type or keyword)
            "[\\(\\.]?"   // possible opening parenthesis or dot
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file
            .match(pattern: expressionPattern)
            .filter {
                $0.1 == [.keyword, .identifier, .typeidentifier, .identifier] ||
                $0.1 == [.keyword, .identifier, .typeidentifier, .keyword]
            }
            .filter { !isFalsePositive(file: file, range: $0.0) }
            .filter { !isIBInspectable(file: file, range: $0.0) }
            .compactMap {
                file.match(pattern: typeAnnotationPattern,
                           excludingSyntaxKinds: SyntaxKind.commentAndStringKinds, range: $0.0).first
            }
    }

    private func isFalsePositive(file: SwiftLintFile, range: NSRange) -> Bool {
        guard let typeNames = getPartsOfExpression(in: file, range: range) else { return false }

        let lhs = typeNames.variableTypeName
        let rhs = typeNames.assigneeName

        if lhs == rhs || (lhs == "Bool" && (rhs == "true" || rhs == "false")) {
            return false
        } else {
            return true
        }
    }

    private func getPartsOfExpression(
        in file: SwiftLintFile, range: NSRange
    ) -> (variableTypeName: String, assigneeName: String)? {
        let substring = file.stringView.substring(with: range)
        let components = substring.components(separatedBy: "=")

        guard
            components.count == 2,
            let variableTypeName = components[0].components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        else {
            return nil
        }

        let charactersToTrimFromRhs = CharacterSet(charactersIn: ".(").union(.whitespaces)
        let assigneeName = components[1].trimmingCharacters(in: charactersToTrimFromRhs)

        return (variableTypeName, assigneeName)
    }

    private func isIBInspectable(file: SwiftLintFile, range: NSRange) -> Bool {
        guard
            let byteRange = file.stringView.NSRangeToByteRange(start: range.location, length: range.length),
            let dict = file.structureDictionary.structures(forByteOffset: byteRange.location).last,
            let kind = dict.declarationKind,
            SwiftDeclarationKind.variableKinds.contains(kind)
        else { return false }

        return dict.enclosedSwiftAttributes.contains(.ibinspectable)
    }
}
