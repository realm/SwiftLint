import Foundation
import SourceKittenFramework
import SwiftSyntax

struct CommaInheritanceRule: OptInRule, SubstitutionCorrectableRule,
                             SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "comma_inheritance",
        name: "Comma Inheritance Rule",
        description: "Use commas to separate types in inheritance lists",
        kind: .style,
        nonTriggeringExamples: #examples([
            "struct A: Codable, Equatable {}",
            "enum B: Codable, Equatable {}",
            "class C: Codable, Equatable {}",
            "protocol D: Codable, Equatable {}",
            "typealias E = Equatable & Codable",
            "func foo<T: Equatable & Codable>(_ param: T) {}",
            """
            protocol G {
                associatedtype Model: Codable, Equatable
            }
            """,
        ]),
        triggeringExamples: #examples([
            "struct A: Codable↓ & Equatable {}",
            "struct A: Codable↓  & Equatable {}",
            "struct A: Codable↓&Equatable {}",
            "struct A: Codable↓& Equatable {}",
            "enum B: Codable↓ & Equatable {}",
            "class C: Codable↓ & Equatable {}",
            "protocol D: Codable↓ & Equatable {}",
            """
            protocol G {
                associatedtype Model: Codable↓ & Equatable
            }
            """,
        ]),
        corrections: #examplesDictionary([
            "struct A: Codable↓ & Equatable {}": "struct A: Codable, Equatable {}",
            "struct A: Codable↓  & Equatable {}": "struct A: Codable, Equatable {}",
            "struct A: Codable↓&Equatable {}": "struct A: Codable, Equatable {}",
            "struct A: Codable↓& Equatable {}": "struct A: Codable, Equatable {}",
            "enum B: Codable↓ & Equatable {}": "enum B: Codable, Equatable {}",
            "class C: Codable↓ & Equatable {}": "class C: Codable, Equatable {}",
            "protocol D: Codable↓ & Equatable {}": "protocol D: Codable, Equatable {}",
            """
            protocol G {
                associatedtype Model: Codable↓ & Equatable
            }
            """: """
            protocol G {
                associatedtype Model: Codable, Equatable
            }
            """,
        ])
    )

    // MARK: - Rule

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableRule

    func substitution(for violationRange: NSRange, in _: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, ", ")
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let visitor = CommaInheritanceRuleVisitor(viewMode: .sourceAccurate)
        return visitor.walk(file: file) { visitor -> [ByteRange] in
            visitor.violationRanges
        }.compactMap {
            file.stringView.byteRangeToNSRange($0)
        }
    }
}

private final class CommaInheritanceRuleVisitor: SyntaxVisitor {
    private(set) var violationRanges: [ByteRange] = []

    override func visitPost(_ node: InheritedTypeSyntax) {
        for type in node.children(viewMode: .sourceAccurate) {
            guard let composition = type.as(CompositionTypeSyntax.self) else {
                continue
            }

            for ampersand in composition.elements.compactMap(\.ampersand) {
                let position: AbsolutePosition
                if let previousToken = ampersand.previousToken(viewMode: .sourceAccurate) {
                    position = previousToken.endPositionBeforeTrailingTrivia
                } else {
                    position = ampersand.position
                }

                violationRanges.append(ByteRange(
                    location: ByteCount(position),
                    length: ByteCount(ampersand.endPosition.utf8Offset - position.utf8Offset)
                ))
            }
        }
    }
}
