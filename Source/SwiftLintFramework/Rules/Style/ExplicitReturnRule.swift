import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct ExplicitReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule, OptInRule {
    public var configuration = ExplicitReturnConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_return",
        name: "Explicit Return",
        description: "Prefer explicit returns in closures, functions and getters.",
        kind: .style,
        nonTriggeringExamples: ExplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ExplicitReturnRuleExamples.triggeringExamples,
        corrections: ExplicitReturnRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violations(file: file).map {
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, byteOffset: $0)
            )
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return violations(file: file).compactMap {
            file.stringView.byteRangeToNSRange(ByteRange(location: $0, length: 0))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "return ")
    }

    private func violations(file: SwiftLintFile) -> [ByteCount] {
        guard let tree = file.syntaxTree else { return [] }

        let visitor = ExplicitReturnVisitor(includedKinds: configuration.includedKinds)
        visitor.walk(tree)

        return visitor.positions.map { ByteCount($0.utf8Offset) }
    }
}

private final class ExplicitReturnVisitor: SyntaxVisitor {
    private let includedKinds: Set<ExplicitReturnConfiguration.ReturnKind>

    private(set) var positions: [AbsolutePosition] = []

    init(includedKinds: Set<ExplicitReturnConfiguration.ReturnKind>) {
        self.includedKinds = includedKinds
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        guard includedKinds.contains(.closure),
              let firstItem = node.statements.first?.item,
              node.statements.count == 1 else { return }

        if firstItem.isImplicitlyReturnable {
            positions.append(firstItem.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        guard includedKinds.contains(.function),
              node.signature.allowsImplicitReturns,
              let firstItem = node.body?.statements.first?.item,
              node.body?.statements.count == 1 else { return }

        if firstItem.isImplicitlyReturnable {
            positions.append(firstItem.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        guard includedKinds.contains(.getter) else { return }

        for binding in node.bindings {
            if let accessor = binding.accessor?.as(CodeBlockSyntax.self) {
                // Shorthand syntax for getters: `var foo: Int { 0 }`
                guard let firstItem = accessor.statements.first?.item,
                      accessor.statements.count == 1 else { continue }

                if firstItem.isImplicitlyReturnable {
                    positions.append(firstItem.positionAfterSkippingLeadingTrivia)
                }
            } else if let accessorBlock = binding.accessor?.as(AccessorBlockSyntax.self) {
                // Full syntax for getters: `var foo: Int { get { 0 } }`
                guard let accessor = accessorBlock.accessors.first(where: { $0.accessorKind.text == "get" }),
                      let firstItem = accessor.body?.statements.first?.item,
                      accessor.body?.statements.count == 1 else { continue }

                if firstItem.isImplicitlyReturnable {
                    positions.append(firstItem.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private extension Syntax {
    var isImplicitlyReturnable: Bool {
        isProtocol(ExprSyntaxProtocol.self)
    }
}

private extension FunctionSignatureSyntax {
    var allowsImplicitReturns: Bool {
        if let simpleType = output?.returnType.as(SimpleTypeIdentifierSyntax.self) {
            return simpleType.name.text != "Void" && simpleType.name.text != "Never"
        } else if let tupleType = output?.returnType.as(TupleTypeSyntax.self) {
            return !tupleType.elements.isEmpty
        } else {
            return output != nil
        }
    }
}
