import Foundation
import SourceKittenFramework

private let typeAndExtensionKinds = SwiftDeclarationKind.typeKinds + [.extension, .protocol]

private extension Dictionary where Key: ExpressibleByStringLiteral {
    func recursiveDeclaredTypeNames() -> [String] {
        let subNames = substructure.flatMap { $0.recursiveDeclaredTypeNames() }
        if let kind = kind.flatMap(SwiftDeclarationKind.init),
            typeAndExtensionKinds.contains(kind), let name = name {
            return [name] + subNames
        }
        return subNames
    }
}

public struct FileNameRule: ConfigurationProviderRule, OptInRule {
    public var configuration = FileNameConfiguration(
        severity: .warning,
        excluded: ["main.swift", "LinuxMain.swift"],
        prefixPattern: "",
        suffixPattern: "\\+.*"
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_name",
        name: "File Name",
        description: "File name should match a type or extension declared in the file (if any).",
        kind: .idiomatic
    )

    public func validate(file: File) -> [StyleViolation] {
        guard let filePath = file.path,
            case let fileName = filePath.bridge().lastPathComponent,
            !configuration.excluded.contains(fileName) else {
            return []
        }

        let prefixRegex = regex("\\A(?:\(configuration.prefixPattern))")
        let suffixRegex = regex("(?:\(configuration.suffixPattern))\\z")

        var typeInFileName = fileName.bridge().deletingPathExtension

        if let match = prefixRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange),
            let range = typeInFileName.nsrangeToIndexRange(match.range) {
            typeInFileName.removeSubrange(range)
        }

        if let match = suffixRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange),
            let range = typeInFileName.nsrangeToIndexRange(match.range) {
            typeInFileName.removeSubrange(range)
        }

        let allDeclaredTypeNames = file.structure.dictionary.recursiveDeclaredTypeNames()
        guard !allDeclaredTypeNames.isEmpty, !allDeclaredTypeNames.contains(typeInFileName) else {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}
