import SourceKittenFramework

struct NestingRule: ConfigurationProviderRule {
    var configuration = NestingConfiguration(typeLevelWarning: 1,
                                             typeLevelError: nil,
                                             functionLevelWarning: 2,
                                             functionLevelError: nil)

    init() {}

    static let description = RuleDescription(
        identifier: "nesting",
        name: "Nesting",
        description:
            "Types should be nested at most 1 level deep, and functions should be nested at most 2 levels deep.",
        kind: .metrics,
        nonTriggeringExamples: NestingRuleExamples.nonTriggeringExamples,
        triggeringExamples: NestingRuleExamples.triggeringExamples
    )

    private let omittedStructureKinds = SwiftDeclarationKind.variableKinds
        .union([.enumcase, .enumelement])
        .map(SwiftStructureKind.declaration)

    private struct ValidationArgs {
        var typeLevel: Int = -1
        var functionLevel: Int = -1
        var previousKind: SwiftStructureKind?
        var violations: [StyleViolation] = []

        func with(previousKind: SwiftStructureKind?) -> ValidationArgs {
            var args = self
            args.previousKind = previousKind
            return args
        }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, substructure: file.structureDictionary.substructure, args: ValidationArgs())
    }

    private func validate(file: SwiftLintFile, substructure: [SourceKittenDictionary],
                          args: ValidationArgs) -> [StyleViolation] {
        return args.violations + substructure.flatMap { dictionary -> [StyleViolation] in
            guard let kindString = dictionary.kind, let structureKind = SwiftStructureKind(kindString) else {
                return validate(file: file, substructure: dictionary.substructure, args: args.with(previousKind: nil))
            }
            guard !omittedStructureKinds.contains(structureKind) else {
                return args.violations
            }
            switch structureKind {
            case let .declaration(declarationKind):
                return validate(file: file, structureKind: structureKind,
                                declarationKind: declarationKind, dictionary: dictionary, args: args)
            case .expression, .statement:
                guard configuration.checkNestingInClosuresAndStatements else {
                    return args.violations
                }
                return validate(file: file, substructure: dictionary.substructure,
                                args: args.with(previousKind: structureKind))
            }
        }
    }

    private func validate(file: SwiftLintFile, structureKind: SwiftStructureKind, declarationKind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary, args: ValidationArgs) -> [StyleViolation] {
        let isTypeOrExtension = SwiftDeclarationKind.typeKinds.contains(declarationKind)
            || SwiftDeclarationKind.extensionKinds.contains(declarationKind)
        let isFunction = SwiftDeclarationKind.functionKinds.contains(declarationKind)

        guard isTypeOrExtension || isFunction else {
            return validate(file: file, substructure: dictionary.substructure,
                            args: args.with(previousKind: structureKind))
        }

        let currentTypeLevel = isTypeOrExtension ? args.typeLevel + 1 : args.typeLevel
        let currentFunctionLevel = isFunction ? args.functionLevel + 1 : args.functionLevel

        var violations = args.violations

        if let violation = levelViolation(file: file, dictionary: dictionary,
                                          previousKind: args.previousKind,
                                          level: isFunction ? currentFunctionLevel : currentTypeLevel,
                                          forFunction: isFunction) {
            violations.append(violation)
        }

        return validate(file: file, substructure: dictionary.substructure,
                        args: ValidationArgs(
                            typeLevel: currentTypeLevel,
                            functionLevel: currentFunctionLevel,
                            previousKind: structureKind,
                            violations: violations
            )
        )
    }

    private func levelViolation(file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                previousKind: SwiftStructureKind?, level: Int, forFunction: Bool) -> StyleViolation? {
        guard let offset = dictionary.offset else {
            return nil
        }

        let targetLevel = forFunction ? configuration.functionLevel : configuration.typeLevel
        var violatingSeverity: ViolationSeverity?

        if configuration.alwaysAllowOneTypeInFunctions,
            case let .declaration(previousDeclarationKind)? = previousKind,
            !SwiftDeclarationKind.functionKinds.contains(previousDeclarationKind) {
            violatingSeverity = configuration.severity(with: targetLevel, for: level)
        } else if forFunction || !configuration.alwaysAllowOneTypeInFunctions || previousKind == nil {
            violatingSeverity = configuration.severity(with: targetLevel, for: level)
        } else {
            violatingSeverity = nil
        }

        guard let severity = violatingSeverity else {
            return nil
        }

        let targetName = forFunction ? "Functions" : "Types"
        let threshold = configuration.threshold(with: targetLevel, for: severity)
        let pluralSuffix = threshold > 1 ? "s" : ""
        return StyleViolation(
            ruleDescription: Self.description,
            severity: severity,
            location: Location(file: file, byteOffset: offset),
            reason: "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep"
        )
    }
}

private enum SwiftStructureKind: Equatable {
    case declaration(SwiftDeclarationKind)
    case expression(SwiftExpressionKind)
    case statement(StatementKind)

    init?(_ structureKind: String) {
        if let declarationKind = SwiftDeclarationKind(rawValue: structureKind) {
            self = .declaration(declarationKind)
        } else if let expressionKind = SwiftExpressionKind(rawValue: structureKind) {
            self = .expression(expressionKind)
        } else if let statementKind = StatementKind(rawValue: structureKind) {
            self = .statement(statementKind)
        } else {
            return nil
        }
    }
}
