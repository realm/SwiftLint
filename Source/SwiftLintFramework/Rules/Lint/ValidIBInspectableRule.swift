import SwiftSyntax

struct ValidIBInspectableRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "valid_ibinspectable",
        name: "Valid IBInspectable",
        description: """
            @IBInspectable should be applied to variables only, have its type explicit and be of a supported type
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              @IBInspectable private var x: Int
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private var x: String?
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private var x: String!
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private var count: Int = 0
            }
            """),
            Example("""
            class Foo {
              private var notInspectable = 0
            }
            """),
            Example("""
            class Foo {
              private let notInspectable: Int
            }
            """),
            Example("""
            class Foo {
              private let notInspectable: UInt8
            }
            """),
            Example("""
            extension Foo {
                @IBInspectable var color: UIColor {
                    set {
                        self.bar.textColor = newValue
                    }

                    get {
                        return self.bar.textColor
                    }
                }
            }
            """),
            Example("""
            class Foo {
                @IBInspectable var borderColor: UIColor? = nil {
                    didSet {
                        updateAppearance()
                    }
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo {
              @IBInspectable private ↓let count: Int
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var insets: UIEdgeInsets
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var count = 0
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var count: Int?
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var count: Int!
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var count: Optional<Int>
            }
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var x: Optional<String>
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    fileprivate static var supportedTypes: Set<String> = {
        // "You can add the IBInspectable attribute to any property in a class declaration,
        // class extension, or category of type: boolean, integer or floating point number, string,
        // localized string, rectangle, point, size, color, range, and nil."
        //
        // from http://help.apple.com/xcode/mac/8.0/#/devf60c1c514

        let referenceTypes = [
            "String",
            "NSString",
            "UIColor",
            "NSColor",
            "UIImage",
            "NSImage"
        ]

        let types = [
            "CGFloat",
            "Float",
            "Double",
            "Bool",
            "CGPoint",
            "NSPoint",
            "CGSize",
            "NSSize",
            "CGRect",
            "NSRect"
        ]

        let intTypes: [String] = ["", "8", "16", "32", "64"].flatMap { size in
            ["U", ""].map { (sign: String) -> String in
                "\(sign)Int\(size)"
            }
        }

        let expandToIncludeOptionals: (String) -> [String] = { [$0, $0 + "!", $0 + "?"] }

        // It seems that only reference types can be used as ImplicitlyUnwrappedOptional or Optional
        return Set(referenceTypes.flatMap(expandToIncludeOptionals) + types + intTypes)
    }()
}

private extension ValidIBInspectableRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [FunctionDeclSyntax.self] }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isInstanceVariable, node.isIBInspectable, node.hasViolation {
                violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension VariableDeclSyntax {
    var isIBInspectable: Bool {
        attributes.contains(attributeNamed: "IBInspectable")
    }

    var hasViolation: Bool {
        isReadOnlyProperty || !isSupportedType
    }

    var isReadOnlyProperty: Bool {
        if letOrVarKeyword.tokenKind == .keyword(.let) {
            return true
        }

        let computedProperty = bindings.contains { binding in
            binding.accessor != nil
        }

        if !computedProperty {
            return false
        }

        return bindings.allSatisfy { binding in
            guard let accessorBlock = binding.accessor?.as(AccessorBlockSyntax.self) else {
                return true
            }

            // if it has a `get`, it needs to have a `set`, otherwise it's readonly
            if accessorBlock.getAccessor != nil {
                return accessorBlock.setAccessor == nil
            }

            return false
        }
    }

    var isSupportedType: Bool {
        bindings.allSatisfy { binding in
            guard let type = binding.typeAnnotation else {
                return false
            }

            return ValidIBInspectableRule.supportedTypes.contains(type.type.trimmedDescription)
        }
    }
}
