import SwiftSyntax

@SwiftSyntaxRule
struct BlockBasedKVORule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "block_based_kvo",
        name: "Block Based KVO",
        description: "Prefer the new block based KVO API with keypaths when using Swift 3.2 or later",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example(#"""
            let observer = foo.observe(\.value, options: [.new]) { (foo, change) in
               print(change.newValue)
            }
            """#),
        ],
        triggeringExamples: [
            Example("""
            class Foo: NSObject {
              override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {}
            }
            """),
            Example("""
            class Foo: NSObject {
              override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                          change: Dictionary<NSKeyValueChangeKey, Any>?,
                                          context: UnsafeMutableRawPointer?) {}
            }
            """),
        ]
    )
}

private extension BlockBasedKVORule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.modifiers.contains(keyword: .override),
                  case let parameterList = node.signature.parameterClause.parameters,
                  parameterList.count == 4,
                  node.name.text == "observeValue",
                  parameterList.map(\.firstName.text) == ["forKeyPath", "of", "change", "context"]
            else {
                return
            }

            let types = parameterList
                .map { $0.type.trimmedDescription.replacingOccurrences(of: " ", with: "") }
            let firstTypes = ["String?", "Any?", "[NSKeyValueChangeKey:Any]?", "UnsafeMutableRawPointer?"]
            let secondTypes = ["String?", "Any?", "Dictionary<NSKeyValueChangeKey,Any>?", "UnsafeMutableRawPointer?"]
            if types == firstTypes || types == secondTypes {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
