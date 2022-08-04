import SourceKittenFramework

public struct OverrideInExtensionRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "override_in_extension",
        name: "Override in Extension",
        description: "Extensions shouldn't override declarations.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("extension Person {\n  var age: Int { return 42 }\n}\n"),
            Example("extension Person {\n  func celebrateBirthday() {}\n}\n"),
            Example("class Employee: Person {\n  override func celebrateBirthday() {}\n}\n"),
            Example("""
            class Foo: NSObject {}
            extension Foo {
                override var description: String { return "" }
            }
            """),
            Example("""
            struct Foo {
                class Bar: NSObject {}
            }
            extension Foo.Bar {
                override var description: String { return "" }
            }
            """)
        ],
        triggeringExamples: [
            Example("extension Person {\n  override ↓var age: Int { return 42 }\n}\n"),
            Example("extension Person {\n  override ↓func celebrateBirthday() {}\n}\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let collector = NamespaceCollector(dictionary: file.structureDictionary)
        let elements = collector.findAllElements(of: [.class, .struct, .enum, .extension])

        let susceptibleNames = Set(elements.compactMap { $0.kind == .class ? $0.name : nil })

        return elements
            .filter { $0.kind == .extension && !susceptibleNames.contains($0.name) }
            .flatMap { element in
                return element.dictionary.substructure.compactMap { element -> ByteCount? in
                    guard element.declarationKind != nil,
                        element.enclosedSwiftAttributes.contains(.override),
                        let offset = element.offset
                    else {
                        return nil
                    }

                    return offset
                }
            }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }
}
