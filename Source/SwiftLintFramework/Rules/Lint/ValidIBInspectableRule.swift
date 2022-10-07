import SwiftSyntax

public struct ValidIBInspectableRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
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
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isInstanceVariable, node.isIBInspectable, node.hasViolation {
                violationPositions.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

private extension VariableDeclSyntax {
    var isInstanceVariable: Bool {
        guard let modifiers = modifiers else {
            return true
        }

        return !modifiers.contains { modifier in
            modifier.name.text == "static" || modifier.name.text == "class"
        }
    }

    var isIBInspectable: Bool {
        attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.text == "IBInspectable"
        } ?? false
    }

    var hasViolation: Bool {
        !isMutableProperty || !isSupportedType
    }

    var isMutableProperty: Bool {
        if letOrVarKeyword.tokenKind == .letKeyword {
            return false
        }

        let computedProperty = bindings.contains { binding in
            binding.accessor != nil
        }

        if !computedProperty {
            return true
        }

        return bindings.allSatisfy { binding in
            binding.accessor?.as(AccessorBlockSyntax.self)?.containsSetAccessor ?? false
        }
    }

    var isSupportedType: Bool {
        bindings.allSatisfy { binding in
            guard let type = binding.typeAnnotation else {
                return false
            }

            return ValidIBInspectableRule.supportedTypes.contains(type.type.withoutTrivia().description)
        }
    }
}

private extension AccessorBlockSyntax {
    var containsSetAccessor: Bool {
        return accessors.contains { accessor in
            accessor.accessorKind.tokenKind == .contextualKeyword("set")
        }
    }
}
