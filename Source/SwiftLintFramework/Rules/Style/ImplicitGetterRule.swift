import Foundation
import SourceKittenFramework

public struct ImplicitGetterRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties and subscripts should avoid using the get keyword.",
        kind: .style,
        nonTriggeringExamples: ImplicitGetterRule.nonTriggeringExamples,
        triggeringExamples: ImplicitGetterRule.triggeringExamples
    )

    private static var nonTriggeringExamples: [String] {
        let commonExamples = [
            """
            class Foo {
                var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            """
            class Foo {
                var foo: Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            "class Foo {\n    var foo: Int\n}",
            """
            class Foo {
                var foo: Int {
                    return getValueFromDisk()
                }
            }
            """,
            """
            class Foo {
                var foo: String {
                    return "get"
                }
            }
            """,
            "protocol Foo {\n    var foo: Int { get }\n",
            "protocol Foo {\n    var foo: Int { get set }\n",
            """
            class Foo {
                var foo: Int {
                    struct Bar {
                        var bar: Int {
                            get { return 1 }
                            set { _ = newValue }
                        }
                    }

                    return Bar().bar
                }
            }
            """,
            """
            var _objCTaggedPointerBits: UInt {
                @inline(__always) get { return 0 }
            }
            """,
            """
            var next: Int? {
                mutating get {
                    defer { self.count += 1 }
                    return self.count
                }
            }
            """
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
            """
            class Foo {
                subscript(i: Int) -> Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                subscript(i: Int) -> Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            "protocol Foo {\n    subscript(i: Int) -> Int { get }\n}",
            "protocol Foo {\n    subscript(i: Int) -> Int { get set }\n}"
        ]
    }

    private static var triggeringExamples: [String] {
        let commonExamples = [
            """
            class Foo {
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
            """
            class Foo {
                var foo: Int {
                    ↓get{ return 20 }
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
            "var foo: Int {\n    ↓get { return 20 }\n}",
            """
            class Foo {
                @objc func bar() {}
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
            """
            class Foo {
                subscript(i: Int) -> Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """
        ]
    }

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\{[^\\{]*?\\s+get\\b"
        let attributesKinds: Set<SyntaxKind> = [.attributeBuiltin, .attributeID]
        let getTokens: [SyntaxToken] = file.rangesAndTokens(matching: pattern).compactMap { _, tokens in
            let kinds = tokens.kinds
            guard let token = tokens.last,
                SyntaxKind(rawValue: token.type) == .keyword,
                attributesKinds.isDisjoint(with: kinds) else {
                    return nil
            }

            return token
        }

        let violatingLocations = getTokens.compactMap { token -> (Int, SwiftDeclarationKind?)? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: token.offset, structure: file.structure).last else {
                return nil
            }

            // If there's a setter, `get` is allowed
            guard dict.setterAccessibility == nil else {
                return nil
            }

            let kind = dict.kind.flatMap(SwiftDeclarationKind.init(rawValue:))
            return (token.offset, kind)
        }

        return violatingLocations.map { offset, kind in
            let reason = kind.map { kind -> String in
                let kindString = kind == .functionSubscript ? "subscripts" : "properties"
                return "Computed read-only \(kindString) should avoid using the get keyword."
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }

    private func declarations(forByteOffset byteOffset: Int,
                              structure: Structure) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()
        let allowedKinds = SwiftDeclarationKind.variableKinds.subtracting([.varParameter])
                                                             .union([.functionSubscript])

        func parse(dictionary: [String: SourceKitRepresentable], parentKind: SwiftDeclarationKind?) {
            // Only accepts declarations which contains a body and contains the
            // searched byteOffset
            guard let kindString = dictionary.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString),
                let bodyOffset = dictionary.bodyOffset,
                let bodyLength = dictionary.bodyLength,
                case let byteRange = NSRange(location: bodyOffset, length: bodyLength),
                NSLocationInRange(byteOffset, byteRange) else {
                    return
            }

            if parentKind != .protocol && allowedKinds.contains(kind) {
                results.append(dictionary)
            }

            for dictionary in dictionary.substructure {
                parse(dictionary: dictionary, parentKind: kind)
            }
        }

        for dictionary in structure.dictionary.substructure {
            parse(dictionary: dictionary, parentKind: nil)
        }

        return results
    }
}
