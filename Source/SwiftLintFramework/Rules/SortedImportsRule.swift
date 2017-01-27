//
//  SortedImportsRule.swift
//  SwiftLint
//
//  Created by Scott Berrevoets on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SortedImportsRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SortedImportsConfiguration(ignoreCase: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted.",
        nonTriggeringExamples: [
            "import AAA\nimport BBB\nimport CCC\nimport DDD",
            "import Alamofire\nimport API",
            "import labc\nimport Ldef",
            "import AAA\nimport enum AAA.Enum\nimport struct AAA.Struct\n@testable import AAA",
            "import AAA\nimport bbb\nimport CCC\nimport @testable DDD",
            "@testable import AAA\nenum AAA { }",
            "import AAA\nimport bbb\n" +
                "import enum AAA.Enum\n" +
                "import enum bbb.Enum\n" +
                "import func AAA.Func\n" +
                "import protocol bbb.Protocol\n" +
                "import struct AAA.Struct\n" +
                "import typealias AAA.Typealias\n" +
                "import var CCC.var\n" +
                "@testable import bbb\n" +
                "@testable import CCC"
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC",
            "@testable import AAA\nimport ↓BBB",
            "import enum AAA.Class\nimport ↓DDD"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let imports = file.parseImports()
        let importPairs = zip(imports, imports.dropFirst())
        return importPairs.flatMap { previous, current in
            let ignoreCase = configuration.ignoreCase
            if current.isLessThan(previous, ignoringCase: ignoreCase) {
                return StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: current.offset)
                )
            }
            return nil
        }
    }

}
