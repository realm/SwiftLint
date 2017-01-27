//
//  DuplicatedImports.swift
//  SwiftLint
//
//  Created by Miguel Revetria on 8/2/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DuplicatedImportsRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() { }

    public static let description = RuleDescription(
        identifier: "duplicated_imports",
        name: "Duplicated Imports",
        description: "Avoid duplicated imports.",
        nonTriggeringExamples: [
            "import AAA\n",
            "import AAA\nimport BBB",
            "import AAA\n@testable import BBB",
            "import AAA\nimport aaa"
        ],
        triggeringExamples: [
            "import AAA\nimport ↓AAA",
            "import AAA\nimport BBB\nimport ↓AAA"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let imports = file.parseImports()
        let sortedModulesAndOffsets = imports.sorted { $0.isLessThan($1) }

        return zip(sortedModulesAndOffsets, sortedModulesAndOffsets.dropFirst())
            .flatMap { previous, current in
                guard previous == current else {
                    return nil
                }
                return StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: current.offset)
                )
            }
    }

}
