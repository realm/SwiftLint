import SourceKittenFramework
import SwiftSyntax

public struct VoidFunctionInTernaryConditionRule: ConfigurationProviderRule, AutomaticTestableRule {
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
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        let visitor = VoidFunctionInTernaryConditionVisitor()
        visitor.walk(syntaxTree)
        return visitor.violations(for: self, in: file)
    }
}

private class VoidFunctionInTernaryConditionVisitor: SyntaxVisitor {
    private var positions = [AbsolutePosition]()

    override func visitPost(_ node: TernaryExprSyntax) {
        guard node.firstChoice.is(FunctionCallExprSyntax.self),
              node.secondChoice.is(FunctionCallExprSyntax.self),
              let parent = node.parent?.as(ExprListSyntax.self),
              !parent.containsAssignment,
              let grandparent = parent.parent,
              grandparent.is(SequenceExprSyntax.self),
              let blockItem = grandparent.parent?.as(CodeBlockItemSyntax.self),
              !blockItem.isClosureImplictReturn else {
            return
        }

        positions.append(node.questionMark.positionAfterSkippingLeadingTrivia)
    }

    func violations(for rule: VoidFunctionInTernaryConditionRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position)))
        }
    }
}

private extension ExprListSyntax {
    var containsAssignment: Bool {
        return children.contains(where: { $0.is(AssignmentExprSyntax.self) })
    }
}

private extension CodeBlockItemSyntax {
    var isClosureImplictReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              let grandparent = parent.parent else {
            return false
        }

        return parent.children.count == 1 && grandparent.is(ClosureExprSyntax.self)
    }
}
