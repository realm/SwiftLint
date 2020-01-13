import SourceKittenFramework

public struct MultilineParametersRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: "Functions and methods parameters should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            SwiftDeclarationKind.functionKinds.contains(kind),
            let nameRange = dictionary.nameByteRange
        else {
            return []
        }

        let parameterRanges = dictionary.substructure.compactMap { subStructure -> ByteRange? in
            guard subStructure.declarationKind == .varParameter else {
                return nil
            }

            return subStructure.byteRange
        }

        var numberOfParameters = 0
        var linesWithParameters = Set<Int>()

        for range in parameterRanges {
            guard
                let line = file.stringView.lineAndCharacter(forByteOffset: range.location)?.line,
                nameRange.contains(range.location),
                range.intersects(parameterRanges)
            else {
                continue
            }

            linesWithParameters.insert(line)
            numberOfParameters += 1
        }

        guard
            linesWithParameters.count > 1,
            numberOfParameters != linesWithParameters.count
        else {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: nameRange.location))]
    }
}
