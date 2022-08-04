import SourceKittenFramework

public struct DuplicateEnumCasesRule: ConfigurationProviderRule, ASTRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "duplicate_enum_cases",
        name: "Duplicate Enum Cases",
        description: "Enum can't contain multiple cases with the same name.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            enum PictureImport {
                case addImage(image: UIImage)
                case addData(data: Data)
            }
            """),
            Example("""
            enum A {
                case add(image: UIImage)
            }
            enum B {
                case add(image: UIImage)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum PictureImport {
                case ↓add(image: UIImage)
                case addURL(url: URL)
                case ↓add(data: Data)
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        let enumElements = substructureElements(of: dictionary, matching: .enumcase)
            .compactMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap { $0 }

        var elementsByName: [String: [ByteCount]] = [:]
        for element in enumElements {
            guard let name = element.name,
                let nameWithoutParameters = name.split(separator: "(").first,
                let offset = element.offset
            else {
                continue
            }

            elementsByName[String(nameWithoutParameters), default: []].append(offset)
        }

        return elementsByName.filter { $0.value.count > 1 }
            .flatMap { $0.value }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }

    private func substructureElements(of dict: SourceKittenDictionary,
                                      matching kind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        return dict.substructure
            .filter { $0.declarationKind == kind }
    }
}
