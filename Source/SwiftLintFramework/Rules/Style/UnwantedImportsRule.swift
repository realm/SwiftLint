import Foundation
import SourceKittenFramework

/// Creates violations when a module that is unwanted gets imported.
public struct UnwantedImportsRule: ConfigurationProviderRule, OptInRule {
    public var configuration = UnwantedImportsConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "unwanted_imports",
        name: "Unwanted Imports",
        description: "Imports that are unwanted should be removed.",
        kind: .style,
        nonTriggeringExamples: [
            "import Foundation",
            "import MyFramework",
            "@testable import MyFramework",
            "// import UIKit",
            "// @testable import UIKit",
            "// import UnwantedFramework",
            "// @testable import UnwantedFramework"
        ],
        triggeringExamples: [
            "import UIKit",
            "@testable import UIKit",
            "import UnwantedFramework",
            "@testable import UnwantedFramework"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        var violations: [StyleViolation] = []

        configuration.unwantedImports.forEach { config in
            let (module, severity) = config
            let pattern = "import\\s+\(module)"
            let matches = file.match(pattern: pattern).filter { $0.1.contains(.keyword) && $0.1.contains(.identifier) }

            matches.forEach {
                violations.append(StyleViolation(ruleDescription: type(of: self).description,
                                                 severity: severity,
                                                 location: Location(file: file, characterOffset: $0.0.location),
                                                 reason: "\"\(module)\" should not be imported"))
            }
        }

        return violations
    }
}
