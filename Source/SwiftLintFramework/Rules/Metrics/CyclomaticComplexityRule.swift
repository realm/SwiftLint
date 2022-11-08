import Foundation
import SourceKittenFramework

struct CyclomaticComplexityRule: ASTRule, ConfigurationProviderRule {
    var configuration = CyclomaticComplexityConfiguration(warning: 10, error: 20)

    init() {}

    static let description = RuleDescription(
        identifier: "cyclomatic_complexity",
        name: "Cyclomatic Complexity",
        description: "Complexity of function bodies should be limited.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("""
            func f1() {
                if true {
                    for _ in 1..5 { }
                }
                if false { }
            }
            """),
            Example("""
            func f(code: Int) -> Int {
                switch code {
                case 0: fallthrough
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                default: return 1
                }
            }
            """),
            Example("""
            func f1() {
                if true {}; if true {}; if true {}; if true {}; if true {}; if true {}
                func f2() {
                    if true {}; if true {}; if true {}; if true {}; if true {}
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓func f1() {
                if true {
                    if true {
                        if false {}
                    }
                }
                if false {}
                let i = 0
                switch i {
                    case 1: break
                    case 2: break
                    case 3: break
                    case 4: break
                    default: break
                }
                for _ in 1...5 {
                    guard true else {
                        return
                    }
                }
            }
            """)
        ]
    )

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let complexity = measureComplexity(in: file, dictionary: dictionary)

        for parameter in configuration.params where complexity > parameter.value {
            let offset = dictionary.offset ?? 0
            let reason = "Function should have complexity \(configuration.length.warning) or less: " +
                         "currently complexity equals \(complexity)"
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: parameter.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: reason)]
        }

        return []
    }

    private func measureComplexity(in file: SwiftLintFile, dictionary: SourceKittenDictionary) -> Int {
        var hasSwitchStatements = false

        let complexity = dictionary.substructure.reduce(0) { complexity, subDict in
            guard subDict.kind != nil else {
                return complexity
            }

            if let declarationKind = subDict.declarationKind,
                SwiftDeclarationKind.functionKinds.contains(declarationKind) {
                return complexity
            }

            guard let statementKind = subDict.statementKind else {
                return complexity + measureComplexity(in: file, dictionary: subDict)
            }

            if statementKind == .switch {
                hasSwitchStatements = true
            }
            let score = configuration.complexityStatements.contains(statementKind) ? 1 : 0
            return complexity +
                score +
                measureComplexity(in: file, dictionary: subDict)
        }

        if hasSwitchStatements && !configuration.ignoresCaseStatements {
            return reduceSwitchComplexity(initialComplexity: complexity, file: file, dictionary: dictionary)
        }

        return complexity
    }

    // Switch complexity is reduced by `fallthrough` cases

    private func reduceSwitchComplexity(initialComplexity complexity: Int, file: SwiftLintFile,
                                        dictionary: SourceKittenDictionary) -> Int {
        let bodyRange = dictionary.bodyByteRange ?? ByteRange(location: 0, length: 0)

        let contents = file.stringView.substringWithByteRange(bodyRange) ?? ""

        let fallthroughCount = contents.components(separatedBy: "fallthrough").count - 1
        return complexity - fallthroughCount
    }
}
