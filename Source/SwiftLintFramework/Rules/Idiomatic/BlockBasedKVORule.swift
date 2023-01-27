import SwiftSyntax

struct BlockBasedKVORule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """#)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension BlockBasedKVORule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.modifiers.containsOverride,
                  case let parameterList = node.signature.input.parameterList,
                  parameterList.count == 4,
                  node.identifier.text == "observeValue",
                  parameterList.compactMap(\.firstName?.text) == ["forKeyPath", "of", "change", "context"]
            else {
                return
            }

            let types = parameterList
                .compactMap { $0.type?.trimmedDescription.replacingOccurrences(of: " ", with: "") }
            let firstTypes = ["String?", "Any?", "[NSKeyValueChangeKey:Any]?", "UnsafeMutableRawPointer?"]
            let secondTypes = ["String?", "Any?", "Dictionary<NSKeyValueChangeKey,Any>?", "UnsafeMutableRawPointer?"]
            if types == firstTypes || types == secondTypes {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
