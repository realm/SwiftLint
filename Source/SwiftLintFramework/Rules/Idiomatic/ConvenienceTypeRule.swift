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
            Example("class DummyClass {}"),
            Example("""
            class Foo: NSObject { // class with Obj-C class property
                class @objc let foo = 1
            }
            """),
            Example("""
            class Foo: NSObject { // class with Obj-C static property
                static @objc let foo = 1
            }
            """),
            Example("""
            class Foo { // non-final class could be inherited
                class let foo = 1
            }
            """),
            Example("""
            class Foo { // non-final class with only final members could still be inherited
                final class let foo = 1
            }
            """),
            Example("""
            class Foo { // @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """),
            Example("""
            class Foo { // @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """),
            Example("""
            final class Foo { // final class, but @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """),
            Example("""
            final class Foo { // final class, but @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """)
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
            """),
            Example("""
            final class Foo { // final class can't be inherited
                class let foo = 1
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
