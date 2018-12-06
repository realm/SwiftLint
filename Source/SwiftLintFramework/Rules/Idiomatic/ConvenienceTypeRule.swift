import SourceKittenFramework

public struct ConvenienceTypeRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "convenience_type",
        name: "Convenience Type",
        description: "Types used for hosting only static members should be implemented as a caseless enum " +
                     "to avoid instantiation.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            """
            enum Math { // enum
              public static let pi = 3.14
            }
            """,
            """
            // class with inheritance
            class MathViewController: UIViewController {
              public static let pi = 3.14
            }
            """,
            """
            @objc class Math: NSObject { // class visible to Obj-C
              public static let pi = 3.14
            }
            """,
            """
            struct Math { // type with non-static declarations
              public static let pi = 3.14
              public let randomNumber = 2
            }
            """,
            "class DummyClass {}"
        ],
        triggeringExamples: [
            """
            ↓struct Math {
              public static let pi = 3.14
            }
            """,
            """
            ↓class Math {
              public static let pi = 3.14
            }
            """,
            """
            ↓struct Math {
              public static let pi = 3.14
              @available(*, unavailable) init() {}
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.offset,
            [.class, .struct].contains(kind),
            dictionary.inheritedTypes.isEmpty,
            !dictionary.substructure.isEmpty else {
                return []
        }

        let containsInstanceDeclarations = dictionary.substructure.contains { dict in
            guard let kind = dict.kind.flatMap(SwiftDeclarationKind.init(rawValue:)) else {
                return false
            }

            let instanceKinds: Set<SwiftDeclarationKind> = [.varInstance, .functionSubscript, .functionMethodInstance]
            guard instanceKinds.contains(kind), let name = dict.name else {
                return false
            }

            if name.hasPrefix("init(") {
                return !isFunctionUnavailable(file: file, dictionary: dict)
            }

            return true
        }

        guard !containsInstanceDeclarations else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isFunctionUnavailable(file: File, dictionary: [String: SourceKitRepresentable]) -> Bool {
        return dictionary.swiftAttributes.contains { dict -> Bool in
            guard dict.attribute.flatMap(SwiftDeclarationAttributeKind.init(rawValue:)) == .available,
                let offset = dict.offset, let length = dict.length,
                let contents = file.contents.bridge().substringWithByteRange(start: offset, length: length) else {
                    return false
            }

            return contents.contains("unavailable")
        }
    }
}
