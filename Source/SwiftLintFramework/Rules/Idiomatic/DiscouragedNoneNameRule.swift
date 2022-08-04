import SourceKittenFramework

public struct DiscouragedNoneNameRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)
    public static var description = RuleDescription(
        identifier: "discouraged_none_name",
        name: "Discouraged None Name",
        description: "Discourages name cases/static members `none`, which can conflict with `Optional<T>.none`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            // Should not trigger unless exactly matches "none"
            Example("""
            enum MyEnum {
                case nOne
            }
            """),
            Example("""
            enum MyEnum {
                case _none
            }
            """),
            Example("""
            enum MyEnum {
                case none_
            }
            """),
            Example("""
            enum MyEnum {
                case none(Any)
            }
            """),
            Example("""
            enum MyEnum {
                case nonenone
            }
            """),
            Example("""
            class MyClass {
                class var nonenone: MyClass { MyClass() }
            }
            """),
            Example("""
            class MyClass {
                static var nonenone = MyClass()
            }
            """),
            Example("""
            class MyClass {
                static let nonenone = MyClass()
            }
            """),
            Example("""
            struct MyStruct {
                static var nonenone = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                static let nonenone = MyStruct()
            }
            """),

            // Should not trigger if not an enum case or static/class member
            Example("""
            struct MyStruct {
                let none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                var none = MyStruct()
            }
            """),
            Example("""
            class MyClass {
                let none = MyClass()
            }
            """),
            Example("""
            class MyClass {
                var none = MyClass()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum MyEnum {
                case ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case a, ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case ↓none, b
            }
            """),
            Example("""
            enum MyEnum {
                case a, ↓none, b
            }
            """),
            Example("""
            enum MyEnum {
                case a
                case ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case ↓none
                case b
            }
            """),
            Example("""
            enum MyEnum {
                case a
                case ↓none
                case b
            }
            """),
            Example("""
            class MyClass {
                ↓static let none = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓static let none: MyClass = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓static var none: MyClass = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓class var none: MyClass { MyClass() }
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var a = MyStruct(), none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct(), a = MyStruct()
            }
            """)
        ]
    )

    public func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard kind.isForValidating && dictionary.isNameInvalid, let offset = dictionary.offset else { return [] }
        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: offset),
                reason: kind.reason
            )
        ]
    }

    public init() {}
}

private extension SwiftDeclarationKind {
    var isForValidating: Bool { self == .enumelement || self == .varClass || self == .varStatic }

    var reason: String {
        var reasonPrefix: String {
            switch self {
            case .enumelement: return "`case`"
            case .varClass: return "`class` member"
            case .varStatic: return "`static` member"
            default: return ""
            }
        }
        let reason = "Avoid naming \(reasonPrefix) `none` as the compiler can think you mean `Optional<T>.none`."
        let recommendation = "Consider using an Optional value instead."
        return "\(reason) \(recommendation)"
    }
}

private extension SourceKittenDictionary {
    var isNameInvalid: Bool { name == "none" }
}
