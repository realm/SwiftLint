import SourceKittenFramework

public struct NestingRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = NestingConfiguration(typeLevelWarning: 1,
                                                    typeLevelError: nil,
                                                    statementLevelWarning: 5,
                                                    statementLevelError: nil)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nesting",
        name: "Nesting",
        description: "Types should be nested at most 1 level deep, " +
                     "and statements should be nested at most 5 levels deep.",
        kind: .metrics,
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap { kind -> [Example] in
            [
                Example("\(kind) Class0 { \(kind) Class1 {} }\n"),
                Example("""
                func func0() {
                    func func1() {
                        func func2() {
                            func func3() {
                                func func4() {
                                    func func5() {
                                    }
                                }
                            }
                        }
                    }
                }
                """)
            ]
        } + [Example("enum Enum0 { enum Enum1 { case Case } }")],
        triggeringExamples: ["class", "struct", "enum"].map { kind -> Example in
            return Example("\(kind) A { \(kind) B { ↓\(kind) C {} } }\n")
        } + [
            Example("""
            func func0() {
                func func1() {
                    func func2() {
                        func func3() {
                            func func4() {
                                func func5() {
                                    ↓func func6() {
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return validate(file: file, kind: kind, dictionary: dictionary, level: 0)
    }

    private func validate(file: SwiftLintFile, kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary,
                          level: Int) -> [StyleViolation] {
        var violations = [StyleViolation]()
        let typeKinds = SwiftDeclarationKind.typeKinds
        if let offset = dictionary.offset {
            let (targetName, targetLevel) = typeKinds.contains(kind)
                ? ("Types", configuration.typeLevel) : ("Statements", configuration.statementLevel)
            if let severity = configuration.severity(with: targetLevel, for: level) {
                let threshold = configuration.threshold(with: targetLevel, for: severity)
                let pluralSuffix = threshold > 1 ? "s" : ""
                violations.append(StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep"))
            }
        }
        violations.append(contentsOf: dictionary.substructure.compactMap { subDict in
            if let kind = subDict.declarationKind {
                return (kind, subDict)
            }
            return nil
        }.flatMap { kind, subDict in
            return validate(file: file, kind: kind, dictionary: subDict, level: level + 1)
        })
        return violations
    }
}
