import SourceKittenFramework

public struct IBInspectableInExtensionRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "ibinspectable_in_extension",
        name: "IBInspectable in Extension",
        description: "Extensions shouldn't add @IBInspectable properties.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              @IBInspectable private var x: Int
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            extension Foo {
              @IBInspectable private var x: Int
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let collector = NamespaceCollector(dictionary: file.structureDictionary)
        let elements = collector.findAllElements(of: [.extension])

        return elements
            .flatMap { element in
                return element.dictionary.substructure.compactMap { element -> ByteCount? in
                    guard element.declarationKind == .varInstance,
                        element.enclosedSwiftAttributes.contains(.ibinspectable),
                        let offset = element.offset
                    else {
                        return nil
                    }

                    return offset
                }
            }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }
}
