import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct VoidFunctionInTernaryConditionRule: ConfigurationProviderRule, SyntaxRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "void_function_in_ternary",
        name: "Void Function in Ternary",
        description: "Using ternary to call Void functions should be avoided.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("let result = success ? foo() : bar()"),
            Example("""
            if success {
                askQuestion()
            } else {
                exit()
            }
            """),
            Example("""
            var price: Double {
                return hasDiscount ? calculatePriceWithDiscount() : calculateRegularPrice()
            }
            """),
            Example("foo(x == 2 ? a() : b())"),
            Example("""
            chevronView.image = collapsed ? .icon(.mediumChevronDown) : .icon(.mediumChevronUp)
            """),
            Example("""
            array.map { elem in
                elem.isEmpty() ? .emptyValue() : .number(elem)
            }
            """)
        ],
        triggeringExamples: [
            Example("success ↓? askQuestion() : exit()"),
            Example("""
            perform { elem in
                elem.isEmpty() ↓? .emptyValue() : .number(elem)
                return 1
            }
            """),
            Example("""
            DispatchQueue.main.async {
                self.sectionViewModels[section].collapsed.toggle()
                self.sectionViewModels[section].collapsed
                    ↓? self.tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                    : self.tableView.insertRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: section), at: .top, animated: true)
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        return validate(file: file, visitor: TernaryVisitor())
        #else
        return []
        #endif
    }
}

#if canImport(SwiftSyntax)
private class TernaryVisitor: SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()

    func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        if node.firstChoice is FunctionCallExprSyntax, node.secondChoice is FunctionCallExprSyntax,
            let parent = node.parent as? ExprListSyntax, !parent.containsAssignment,
            parent.parent is SequenceExprSyntax,
            let blockItem = parent.parent?.parent as? CodeBlockItemSyntax, !blockItem.isClosureImplictReturn {
            positions.append(node.questionMark.positionAfterSkippingLeadingTrivia)
        }

        return .visitChildren
    }

    func violations(for rule: VoidFunctionInTernaryConditionRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private extension ExprListSyntax {
    var containsAssignment: Bool {
        return children.contains(where: { $0 is AssignmentExprSyntax })
    }
}

private extension CodeBlockItemSyntax {
    var isClosureImplictReturn: Bool {
        guard let parent = parent as? CodeBlockItemListSyntax else {
            return false
        }

        return Array(parent.children).count == 1 && parent.parent is ClosureExprSyntax
    }
}
#endif
