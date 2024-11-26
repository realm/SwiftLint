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
        let allDeclaredTypeNames = TypeNameCollectingVisitor(
            requireFullyQualifiedNames: configuration.requireFullyQualifiedNames
        )
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
    /// All of a visited node's ancestor type names if that node is nested, starting with the furthest
    /// ancestor and ending with the direct parent
    private var ancestorNames = Stack<String>()

    /// All of the type names found in the file
    private(set) var names: Set<String> = []

    /// If true, nested types are only allowed in the file name when used by their fully-qualified name
    /// (e.g. `My.Nested.Type` and not just `Type`)
    private let requireFullyQualifiedNames: Bool

    init(requireFullyQualifiedNames: Bool) {
        self.requireFullyQualifiedNames = requireFullyQualifiedNames
        super.init(viewMode: .sourceAccurate)
    }

    /// Calls `visit(name:)` using the name of the provided node
    private func visit(node: some NamedDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(name: node.name.trimmedDescription)
    }

    /// Visits a node with the provided name, storing that name as an ancestor type name to prepend to
    /// any children to form their fully-qualified names
    private func visit(name: String) -> SyntaxVisitorContinueKind {
        let fullyQualifiedName = (ancestorNames + [name]).joined(separator: ".")
        names.insert(fullyQualifiedName)

        // If the options don't require only fully-qualified names, then we will allow this node's
        // name to be used by itself
        if !requireFullyQualifiedNames {
            names.insert(name)
        }

        ancestorNames.push(name)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: ClassDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: ActorDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: StructDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: TypeAliasDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: EnumDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(node: node)
    }

    override func visitPost(_: ProtocolDeclSyntax) {
        ancestorNames.pop()
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        visit(name: node.extendedType.trimmedDescription)
    }

    override func visitPost(_: ExtensionDeclSyntax) {
        ancestorNames.pop()
    }
}
