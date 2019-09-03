import SourceKittenFramework

public struct NPathComplexityRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = CyclomaticComplexityConfiguration(warning: 200, error: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "npath_complexity",
        name: "NPath Complexity",
        description: "The number of paths of function bodies should be limited.",
        kind: .metrics,
        nonTriggeringExamples: [
            """
            // NPath Complexity: 6
            func nonTriggering() {
                if true {
                    for _ in 1..5 {
                        print("non triggering")
                    }
                }
                if false {
                    print("non triggering")
                }
            }
            """,
            """
            // NPath Complexity: 11
            func switchCase(code: Int) -> Int {
                switch code {
                case 0: fallthrough
                case 1: return 1
                case 2: return 2
                case 3: return 3
                case 4: return 4
                case 5: return 5
                case 6: return 6
                case 7: return 7
                case 8: return 8
                case 9: return 9
                default: return 0
                }
            }
            """,
            """
            // NPath Complexity: 64
            func nestedFunctions() {
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
                // NPath Complexity: 4
                func innerFunction() {
                    if true {}
                    if true {}
                }
            }
            """
        ],
        triggeringExamples: [
            """
            // NPath Complexity: 256
            ↓func triggeringFunction() {
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
                if true {}
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let complexity = measureComplexity(in: file, dictionary: dictionary).totalPaths

        for parameter in configuration.params where complexity > parameter.value {
            let offset = dictionary.offset ?? 0
            let reason = "Function should have complexity \(configuration.length.warning) or less: " +
            "currently complexity equals \(complexity)"
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: parameter.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: reason)]
        }

        return []
    }

    private func measureComplexity(in file: SwiftLintFile, dictionary: SourceKittenDictionary
                                  ) -> (totalPaths: Int, currentPaths: Int) {
        let complexity = dictionary.substructure.reduce((totalPaths: 1, currentPaths: 1)) { complexity, subDict in
            guard let kind = subDict.kind else {
                return complexity
            }

            if let declarationKind = SwiftDeclarationKind(rawValue: kind),
                SwiftDeclarationKind.functionKinds.contains(declarationKind) {
                return complexity
            }

            guard let statementKind = StatementKind(rawValue: kind) else {
                let subComplexity = measureComplexity(in: file, dictionary: subDict)
                return (totalPaths: complexity.totalPaths * subComplexity.totalPaths,
                        currentPaths: subComplexity.currentPaths)
            }

            let score = configuration.complexityStatements.contains(statementKind) ? 1 : 0

            // The complexity of everything inside the if/guard/switch
            let subScore = measureComplexity(in: file, dictionary: subDict)

            // subScore.totalPaths is always at least one.
            let totalPaths = complexity.totalPaths + complexity.currentPaths * (score + subScore.totalPaths - 1)

            // Guard always exits. Return the same current paths as input paths.
            if statementKind == .guard {
                return (totalPaths: totalPaths, currentPaths: complexity.currentPaths * score)
            }

            // Remove one path since a switch will always be entered.
            if statementKind == .switch {
                return (totalPaths: totalPaths - 1,
                        currentPaths: complexity.currentPaths * (score + subScore.totalPaths) - 1)
            }

            if statementKind == .case {
                return (totalPaths: totalPaths, currentPaths: complexity.currentPaths * score)
            }

            return (totalPaths: totalPaths, currentPaths: complexity.currentPaths * (score + subScore.totalPaths))
        }

        return complexity
    }
}
