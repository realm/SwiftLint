import SourceKittenFramework

public struct DuplicateEnumCasesRule: ConfigurationProviderRule, ASTRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "duplicate_enum_cases",
        name: "Duplicate Enum Cases",
        description: "Enum can't contain multiple cases with the same name.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            enum PictureImport {
                case addImage(image: UIImage)
                case addData(data: Data)
            }
            """,
            """
            enum A {
                case add(image: UIImage)
            }
            enum B {
                case add(image: UIImage)
            }
            """
        ],
        triggeringExamples: [
            """
            enum PictureImport {
                case ↓add(image: UIImage)
                case addURL(url: URL)
                case ↓add(data: Data)
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        let enumElements = substructureElements(of: dictionary, matching: .enumcase)
            .compactMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap { $0 }

        var elementsByName: [String: [Int]] = [:]
        for element in enumElements {
            guard let name = element.name,
                let nameWithoutParameters = name.split(separator: "(").first,
                let offset = element.offset else {
                continue
            }

            elementsByName[String(nameWithoutParameters), default: []].append(offset)
        }

        return elementsByName.filter { $0.value.count > 1 }
            .flatMap { $0.value }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }

    private func substructureElements(of dict: SourceKittenDictionary,
                                      matching kind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        return dict.substructure
            .filter { $0.kind.flatMap(SwiftDeclarationKind.init) == kind }
    }
}
