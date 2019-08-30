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
            "func f1() {\nif true {\nfor _ in 1..5 { } }\nif false { }\n}",
            "func f(code: Int) -> Int {\n" +
                "switch code {\n case 0: fallthrough\n case 0: return 1\n case 0: return 1\n" +
                " case 0: return 1\n case 0: return 1\n case 0: return 1\n case 0: return 1\n" +
                " case 0: return 1\n case 0: return 1\n default: return 1\n }\n}",
            "func f1() {" +
                "if true {}; if true {}; if true {}; if true {}; if true {}; if true {}\n" +
                "func f2() {\n" +
                "if true {}; if true {}; if true {}; if true {}; if true {}\n" +
            "}}"
        ],
        triggeringExamples: [
            "↓func f1() {\n if true {}\n if true {}\n if true {}\n if true {}\n if true {}\n if true {}\n" +
                " if true {}\n if true {}\n}"
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
