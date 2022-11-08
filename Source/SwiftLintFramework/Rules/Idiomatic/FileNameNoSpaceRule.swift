import Foundation
import SourceKittenFramework

struct FileNameNoSpaceRule: ConfigurationProviderRule, OptInRule, SourceKitFreeRule {
    var configuration = FileNameNoSpaceConfiguration(
        severity: .warning,
        excluded: []
    )

    init() {}

    static let description = RuleDescription(
        identifier: "file_name_no_space",
        name: "File Name No Space",
        description: "File name should not contain any whitespace.",
        kind: .idiomatic
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let filePath = file.path,
            case let fileName = filePath.bridge().lastPathComponent,
            !configuration.excluded.contains(fileName),
            fileName.rangeOfCharacter(from: .whitespaces) != nil else {
            return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}
