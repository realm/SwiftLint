import Foundation
import SourceKittenFramework
import SwiftSyntax

struct CommaInheritanceRule: OptInRule, SubstitutionCorrectableRule, ConfigurationProviderRule,
                                    SourceKitFreeRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "comma_inheritance",
        name: "Comma Inheritance Rule",
        description: "Use commas to separate types in inheritance lists",
        kind: .style,
        nonTriggeringExamples: [
            Example("struct A: Codable, Equatable {}"),
            Example("enum B: Codable, Equatable {}"),
            Example("class C: Codable, Equatable {}"),
            Example("protocol D: Codable, Equatable {}"),
            Example("typealias E = Equatable & Codable"),
            Example("func foo<T: Equatable & Codable>(_ param: T) {}"),
            Example("""
            protocol G {
                associatedtype Model: Codable, Equatable
            }
            """)
        ],
        triggeringExamples: [
            Example("struct A: Codable↓ & Equatable {}"),
            Example("struct A: Codable↓  & Equatable {}"),
            Example("struct A: Codable↓&Equatable {}"),
            Example("struct A: Codable↓& Equatable {}"),
            Example("enum B: Codable↓ & Equatable {}"),
            Example("class C: Codable↓ & Equatable {}"),
            Example("protocol D: Codable↓ & Equatable {}"),
            Example("""
            protocol G {
                associatedtype Model: Codable↓ & Equatable
            }
            """)
        ],
        corrections: [
            Example("struct A: Codable↓ & Equatable {}"): Example("struct A: Codable, Equatable {}"),
            Example("struct A: Codable↓  & Equatable {}"): Example("struct A: Codable, Equatable {}"),
            Example("struct A: Codable↓&Equatable {}"): Example("struct A: Codable, Equatable {}"),
            Example("struct A: Codable↓& Equatable {}"): Example("struct A: Codable, Equatable {}"),
            Example("enum B: Codable↓ & Equatable {}"): Example("enum B: Codable, Equatable {}"),
            Example("class C: Codable↓ & Equatable {}"): Example("class C: Codable, Equatable {}"),
            Example("protocol D: Codable↓ & Equatable {}"): Example("protocol D: Codable, Equatable {}"),
            Example("""
            protocol G {
                associatedtype Model: Codable↓ & Equatable
            }
            """): Example("""
            protocol G {
                associatedtype Model: Codable, Equatable
            }
            """)
        ]
    )

    // MARK: - Rule

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableRule

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, ", ")
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
                if let previousToken = ampersand.previousToken {
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
