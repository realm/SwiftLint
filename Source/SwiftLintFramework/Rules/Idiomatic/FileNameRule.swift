import SwiftSyntax

struct FileNameRule: ConfigurationProviderRule, OptInRule, SourceKitFreeRule {
    var configuration = FileNameConfiguration(
        severity: .warning,
        excluded: ["main.swift", "LinuxMain.swift"],
        prefixPattern: "",
        suffixPattern: "\\+.*",
        nestedTypeSeparator: "."
    )

    init() {}

    static let description = RuleDescription(
        identifier: "file_name",
        name: "File Name",
        description: "File name should match a type or extension declared in the file (if any)",
        kind: .idiomatic
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let filePath = file.path,
            case let fileName = filePath.bridge().lastPathComponent,
            !configuration.excluded.contains(fileName) else {
            return []
        }

        let prefixRegex = regex("\\A(?:\(configuration.prefixPattern))")
        let suffixRegex = regex("(?:\(configuration.suffixPattern))\\z")

        var typeInFileName = fileName.bridge().deletingPathExtension

        // Process prefix
        if let match = prefixRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange),
            let range = typeInFileName.nsrangeToIndexRange(match.range) {
            typeInFileName.removeSubrange(range)
        }

        // Process suffix
        if let match = suffixRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange),
            let range = typeInFileName.nsrangeToIndexRange(match.range) {
            typeInFileName.removeSubrange(range)
        }

        // Process nested type separator
        let allDeclaredTypeNames = TypeNameCollectingVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.names)
            .map {
                $0.replacingOccurrences(of: ".", with: configuration.nestedTypeSeparator)
            }

        guard allDeclaredTypeNames.isNotEmpty, !allDeclaredTypeNames.contains(typeInFileName) else {
            return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}

private class TypeNameCollectingVisitor: SyntaxVisitor {
    private(set) var names: Set<String> = []

    override func visitPost(_ node: ClassDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: StructDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: TypealiasDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        names.insert(node.identifier.text)
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        names.insert(node.extendedType.trimmedDescription)
    }
}
