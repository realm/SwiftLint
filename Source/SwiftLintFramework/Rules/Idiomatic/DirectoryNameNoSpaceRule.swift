import Foundation
import SourceKittenFramework

public struct DirectoryNameNoSpaceRule: ConfigurationProviderRule, OptInRule {
    public var configuration = DirectoryNameNoSpaceConfiguration(
        severity: .warning,
        excluded: [],
        parentDirectory: ""
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "directory_name_no_space",
        name: "Directory Name No Space",
        description: "Directory names should not contain any whitespace.",
        kind: .idiomatic
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let filePath = file.path,
            case let directories = filePath.bridge().components(separatedBy: "/"),
            let parentDirectoryIndex = directories.firstIndex(of: configuration.parentDirectory),
            directories.suffix(from: parentDirectoryIndex).prefix(upTo: directories.count - 1).allSatisfy({
                !configuration.excluded.contains($0)
            }),
            !directories.suffix(from: parentDirectoryIndex).prefix(upTo: directories.count - 1).allSatisfy({
                $0.rangeOfCharacter(from: .whitespaces) == nil
            }) else {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}
