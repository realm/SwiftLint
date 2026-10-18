import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct ValidIBInspectableRule: Rule {
    var configuration = ValidIBInspectableConfiguration()

    static let description = RuleDescription(
        identifier: "valid_ibinspectable",
        name: "Valid IBInspectable",
        description: """
            @IBInspectable should be applied to variables only, have its type explicit and be of a supported type
            """,
        kind: .lint,
        nonTriggeringExamples: #examples([
            "class Foo { @IBInspectable var angle: CLLocationDegrees }"
                .asExample(configuration: ["additional_types": ["CLLocationDegrees"]]),
            "class Foo { @IBInspectable var angle: Module.Angle }"
                .asExample(configuration: ["additional_types": ["Module.Angle", "Angle", "Angle"]]),
            "class Foo { @IBInspectable var name: String? }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            "class Foo { @IBInspectable var angle: Angle? }"
                .asExample(configuration: ["additional_types": ["Angle?"]]),
            "class Foo { @IBInspectable var angle: Angle { get { 0 } set {} } }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            """
            class Foo {
              @IBInspectable private var x: Int
            }
            """,
            """
            class Foo {
              @IBInspectable private var x: String?
            }
            """,
            """
            class Foo {
              @IBInspectable private var x: String!
            }
            """,
            """
            class Foo {
              @IBInspectable private var count: Int = 0
            }
            """,
            """
            class Foo {
              private var notInspectable = 0
            }
            """,
            """
            class Foo {
              private let notInspectable: Int
            }
            """,
            """
            class Foo {
              private let notInspectable: UInt8
            }
            """,
            """
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
            """,
            """
            class Foo {
                @IBInspectable var borderColor: UIColor? = nil {
                    didSet {
                        updateAppearance()
                    }
                }
            }
            """,
        ]),
        triggeringExamples: #examples([
            "class Foo { @IBInspectable ↓var angle: CLLocationDegrees }",
            "class Foo { @IBInspectable ↓var angle: Angle }"
                .asExample(configuration: ["additional_types": [String]()]),
            "class Foo { @IBInspectable ↓var angle: Angle? }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            "class Foo { @IBInspectable ↓var angle: Angle! }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            "class Foo { @IBInspectable ↓let angle: Angle = 0 }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            "class Foo { @IBInspectable ↓var angle = 0 }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            "class Foo { @IBInspectable ↓var angle: Angle { get { 0 } } }"
                .asExample(configuration: ["additional_types": ["Angle"]]),
            """
            class Foo {
              @IBInspectable private ↓let count: Int
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var insets: UIEdgeInsets
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var count = 0
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var count: Int?
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var count: Int!
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var count: Optional<Int>
            }
            """,
            """
            class Foo {
              @IBInspectable private ↓var x: Optional<String>
            }
            """,
        ])
    )

    fileprivate static let supportedTypes: Set<String> = {
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
            "NSImage",
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
            "NSRect",
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
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [FunctionDeclSyntax.self] }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isInstanceVariable, node.isIBInspectable,
               node.isReadOnlyProperty || !node.isSupportedType(additionalTypes: configuration.additionalTypes) {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension VariableDeclSyntax {
    var isIBInspectable: Bool {
        attributes.contains(attributeNamed: "IBInspectable")
    }

    var isReadOnlyProperty: Bool {
        if bindingSpecifier.tokenKind == .keyword(.let) {
            return true
        }

        let computedProperty = bindings.contains { binding in
            binding.accessorBlock != nil
        }

        if !computedProperty {
            return false
        }

        return bindings.allSatisfy { binding in
            guard let accessorBlock = binding.accessorBlock else {
                return true
            }

            // if it has a `get`, it needs to have a `set`, otherwise it's readonly
            if accessorBlock.getAccessor != nil {
                return accessorBlock.setAccessor == nil
            }

            return false
        }
    }

    func isSupportedType(additionalTypes: Set<String>) -> Bool {
        bindings.allSatisfy { binding in
            guard let type = binding.typeAnnotation else {
                return false
            }

            let name = type.type.trimmedDescription
            return ValidIBInspectableRule.supportedTypes.contains(name) || additionalTypes.contains(name)
        }
    }
}
