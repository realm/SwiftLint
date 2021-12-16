import Foundation
import SourceKittenFramework

public struct EnvironmentInViewOrViewModifierRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "environment_in_view_or_viewmodifier",
        name: "Environment in View or ViewModifier",
        description: "@Environment should only be used in structs implementing `View` or `ViewModifier`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            struct Good: View {
                @Environment(\\.keyPath) var variable
            }
            """),
            Example("""
            struct Good: View {
                @Environment(
                    \\.aVeryLongKeyPathName
                ) var variable
            }
            """),
            Example("""
            struct Good: ViewModifier {
                @Environment(\\.keyPath) var variable
            }
            """),
            Example("""
            struct Good: View {
                @CustomPropertyWrapper @Environment(\\.keyPath) var variable
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct Bad: NotAView {
                @Environment(\\.keyPath) var variable
            }
            """)
        ]
    )

    private let environmentPropertyWrapper = regex("@Environment\\(.*?\\)")

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let collector = NamespaceCollector(dictionary: file.structureDictionary)
        let elements = collector.findAllElements(of: [.struct])

        return elements
            .filter {
                return !$0.dictionary.inheritedTypes.contains(where: { $0 == "View" || $0 == "ViewModifier" })
            }
            .flatMap { element in
                return element.dictionary.substructure.compactMap { subElement -> [ByteCount] in
                    guard subElement.declarationKind == .varInstance else { return [] }
                    return subElement.swiftAttributes.compactMap { attribute -> ByteCount? in
                        guard
                            let offset = attribute.value["key.offset"] as? Int64,
                            let length = attribute.value["key.length"] as? Int64,
                            let attributeString = file.stringView.substringWithByteRange(
                                ByteRange(location: ByteCount(offset), length: ByteCount(length))
                            )
                        else { return nil }
                        let range = NSRange(location: 0, length: attributeString.count)
                        let matches = environmentPropertyWrapper.numberOfMatches(
                            in: attributeString,
                            options: [],
                            range: range
                        )
                        return matches > 0 ? ByteCount(offset) : nil
                    }
                }
            }
            .flatMap { $0 }
            .map {
                StyleViolation(ruleDescription: Self.description, location: Location(file: file, byteOffset: $0))
            }
    }
}
