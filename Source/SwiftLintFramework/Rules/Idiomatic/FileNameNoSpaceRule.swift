import Foundation
import SourceKittenFramework

private let typeAndExtensionKinds = SwiftDeclarationKind.typeKinds + [.extension, .protocol]

public struct FileNameNoSpaceRule: ConfigurationProviderRule, OptInRule {
    public var configuration = FileNameNoSpaceConfiguration(
        severity: .warning,
        excluded: [],
        suffixPattern: "\\.*"
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_name_no_space",
        name: "File Name No Space",
        description: "File name should not contain any whitespace.",
        kind: .idiomatic
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let filePath = file.path,
            case let fileName = filePath.bridge().lastPathComponent,
            !configuration.excluded.contains(fileName) else {
            return []
        }

        let suffixRegex = regex("(?:\(configuration.suffixPattern))\\z")
        let whitespaceRegex = regex("(?:[\\s])")

        var typeInFileName = fileName.bridge().deletingPathExtension

        // Process suffix
        if let match = suffixRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange),
            let range = typeInFileName.nsrangeToIndexRange(match.range) {
            typeInFileName.removeSubrange(range)
        }

        if whitespaceRegex.firstMatch(in: typeInFileName, options: [], range: typeInFileName.fullNSRange) == nil {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}
