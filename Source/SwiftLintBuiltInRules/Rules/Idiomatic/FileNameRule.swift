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

    /// Visits a node to collect its type name and store it as an ancestor type name to prepend to any
    /// children to form their fully-qualified type names
    private func visitNode(_ node: some TypeNameCollectible) -> SyntaxVisitorContinueKind {
        let name = node.typeName
        let fullyQualifiedName = (ancestorNames + [name]).joined(separator: ".")
        names.insert(fullyQualifiedName)

        if !requireFullyQualifiedNames {
            names.insert(name)
        }

        ancestorNames.push(node.typeName)
        return .visitChildren
    }

    /// Removes a node's type name as an ancestor type name once all of its children have been visited
    private func visitNodePost(_: some TypeNameCollectible) {
        ancestorNames.pop()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        visitNodePost(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        visitNode(node)
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        visitNodePost(node)
    }
}

/// A protocol for types that have a type name that can be collected
private protocol TypeNameCollectible {
    var typeName: String { get }
}

extension TypeNameCollectible where Self: NamedDeclSyntax {
    var typeName: String {
        name.trimmedDescription
    }
}
extension ClassDeclSyntax: TypeNameCollectible {}
extension ActorDeclSyntax: TypeNameCollectible {}
extension StructDeclSyntax: TypeNameCollectible {}
extension TypeAliasDeclSyntax: TypeNameCollectible {}
extension EnumDeclSyntax: TypeNameCollectible {}
extension ProtocolDeclSyntax: TypeNameCollectible {}

extension ExtensionDeclSyntax: TypeNameCollectible {
    public var typeName: String {
        extendedType.trimmedDescription
    }
}
