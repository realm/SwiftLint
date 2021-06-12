import SourceKittenFramework

public struct ObservableObjectMainActorRule: ASTRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "observable_object_main_actor",
        name: "Observable Object Main Actor",
        description: """
        ObservableObject should be annotated with @MainActor to ensure \
        that any updates to @Published state occur on the main thread.
        """,
        kind: .idiomatic,
        minSwiftVersion: .fiveDotFive,
        nonTriggeringExamples: [
            Example("""
            @MainActor
            class ViewModel: ObservableObject {
                //...
            }
            """),
            Example("""
            @MainActor class ViewModel: ObservableObject {
                //...
            }
            """),
            Example("""
            @MainActor class SomeOtherThing {
                //...
            }
            """),
            Example("""
            @MainActor class SomeOtherThing {
                //...
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓class ViewModel: ObservableObject {
                //...
            }
            """)
        ]
    )

    public func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard kind == .class,
            dictionary.inheritedTypes.contains("ObservableObject"),
            let offset = dictionary.offset else {
            return []
        }

        let isMainActorAttribute = dictionary.swiftAttributes.contains(where: { attribute in
            if let byteRange = attribute.byteRange,
                let contents = file.stringView.substringWithByteRange(byteRange) {
                return contents == "@MainActor"
            }
            return false
        })

        if isMainActorAttribute { return [] }

        return [
            StyleViolation(
                ruleDescription: Self.description,
                location: Location(file: file, byteOffset: offset)
            )
        ]
    }
}
