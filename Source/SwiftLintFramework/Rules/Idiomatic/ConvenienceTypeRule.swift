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
            Example("""
            enum Math { // enum
              public static let pi = 3.14
            }
            """),
            Example("""
            // class with inheritance
            class MathViewController: UIViewController {
              public static let pi = 3.14
            }
            """),
            Example("""
            @objc class Math: NSObject { // class visible to Obj-C
              public static let pi = 3.14
            }
            """),
            Example("""
            struct Math { // type with non-static declarations
              public static let pi = 3.14
              public let randomNumber = 2
            }
            """),
            Example("class DummyClass {}")
        ],
        triggeringExamples: [
            Example("""
            ↓struct Math {
              public static let pi = 3.14
            }
            """),
            Example("""
            ↓class Math {
              public static let pi = 3.14
            }
            """),
            Example("""
            ↓struct Math {
              public static let pi = 3.14
              @available(*, unavailable) init() {}
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.offset,
            [.class, .struct].contains(kind),
            dictionary.inheritedTypes.isEmpty,
            !dictionary.substructure.isEmpty else {
                return []
        }

        let containsInstanceDeclarations = dictionary.substructure.contains { dict in
            guard let kind = dict.declarationKind else {
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

    private func isFunctionUnavailable(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> Bool {
        return dictionary.swiftAttributes.contains { dict -> Bool in
            guard dict.attribute.flatMap(SwiftDeclarationAttributeKind.init(rawValue:)) == .available,
                let contents = dict.byteRange.flatMap(file.stringView.substringWithByteRange)
            else {
                return false
            }

            return contents.contains("unavailable")
        }
    }
}
