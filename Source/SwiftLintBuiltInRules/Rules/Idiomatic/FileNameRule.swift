import SwiftSyntax

struct FileNameRule: OptInRule, SourceKitFreeRule {
    var configuration = FileNameConfiguration()

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
        let allDeclaredTypeNames = TypeNameCollectingVisitor(requireFullyQualifiedNames: configuration.fullyQualified)
            .walk(tree: file.syntaxTree, handler: \.names)
            .map {
                $0.replacingOccurrences(of: ".", with: configuration.nestedTypeSeparator)
            }

        guard allDeclaredTypeNames.isNotEmpty, !allDeclaredTypeNames.contains(typeInFileName) else {
            return []
        }

        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: filePath, line: 1)
            ),
        ]
    }
}

private class TypeNameCollectingVisitor: SyntaxVisitor {
    // All of a visited node's ancestor type names if that node is nested, starting with the furthest
    // ancestor and ending with the direct parent
    private var ancestorNames: [String] = []

    // All of the type names found in the file
    private(set) var names: Set<String> = []

    // If true, nested types are only allowed in the file name when used by their fully-qualified name
    // (e.g. `My.Nested.Type` and not just `Type`)
    private let requireFullyQualifiedNames: Bool

    init(requireFullyQualifiedNames: Bool) {
        self.requireFullyQualifiedNames = requireFullyQualifiedNames
        super.init(viewMode: .sourceAccurate)
    }

    private func addVisitedNodeName(_ name: String) {
        let fullyQualifiedName = (ancestorNames + [name]).joined(separator: ".")
        names.insert(fullyQualifiedName)

        if !requireFullyQualifiedNames {
            names.insert(name)
        }
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.name.text)
        return .visitChildren
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.name.text)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        ancestorNames.append(node.extendedType.trimmedDescription)
        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        ancestorNames.removeLast()
        addVisitedNodeName(node.extendedType.trimmedDescription)
    }
}
