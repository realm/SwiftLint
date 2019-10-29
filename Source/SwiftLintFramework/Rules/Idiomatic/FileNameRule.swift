import Foundation
import SourceKittenFramework

private let typeAndExtensionKinds = SwiftDeclarationKind.typeKinds + [.extension, .protocol]

private extension SourceKittenDictionary {
    func recursiveDeclaredTypeNames() -> [String] {
        let subNames = substructure.flatMap { $0.recursiveDeclaredTypeNames() }
        if let kind = declarationKind,
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
        suffixPattern: "\\+.*",
        nestedTypeSeparator: "."
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_name",
        name: "File Name",
        description: "File name should match a type or extension declared in the file (if any).",
        kind: .idiomatic
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
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
        let dictionary = file.structureDictionary
        let allDeclaredTypeNames = dictionary.recursiveDeclaredTypeNames().map {
            $0.replacingOccurrences(of: ".", with: configuration.nestedTypeSeparator)
        }

        guard !allDeclaredTypeNames.isEmpty, !allDeclaredTypeNames.contains(typeInFileName) else {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}
