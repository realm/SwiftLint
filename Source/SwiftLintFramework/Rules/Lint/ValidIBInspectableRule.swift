import Foundation
import SourceKittenFramework

public struct ValidIBInspectableRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    private static let supportedTypes = Self.createSupportedTypes()

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
              @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<Int>
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
            """),
            Example("""
            class Foo {
              @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<String>
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if IBInspectable
        let isIBInspectable = dictionary.enclosedSwiftAttributes.contains(.ibinspectable)
        guard isIBInspectable else {
            return []
        }

        let shouldMakeViolation: Bool
        if !file.isMutableProperty(dictionary) {
            shouldMakeViolation = true
        } else if let type = dictionary.typeName,
            Self.supportedTypes.contains(type) {
            shouldMakeViolation = false
        } else {
            // Variable should have explicit type or IB won't recognize it
            // Variable should be of one of the supported types
            shouldMakeViolation = true
        }

        guard shouldMakeViolation else {
            return []
        }

        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: location)
        ]
    }

    private static func createSupportedTypes() -> [String] {
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
        return referenceTypes.flatMap(expandToIncludeOptionals) + types + intTypes
    }
}

private extension SwiftLintFile {
    func isMutableProperty(_ dictionary: SourceKittenDictionary) -> Bool {
        if dictionary.setterAccessibility != nil {
            return true
        }

        if SwiftVersion.current >= .fiveDotTwo,
            let range = dictionary.byteRange.map(stringView.byteRangeToNSRange) {
            return hasSetToken(in: range)
        } else {
            return false
        }
    }

    private func hasSetToken(in range: NSRange?) -> Bool {
        return rangesAndTokens(matching: "\\bset\\b", range: range).contains { _, tokens in
            return tokens.count == 1 && tokens[0].kind == .keyword
        }
    }
}
