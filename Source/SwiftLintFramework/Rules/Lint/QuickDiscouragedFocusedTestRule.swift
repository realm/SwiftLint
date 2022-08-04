import SourceKittenFramework

public struct QuickDiscouragedFocusedTestRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_focused_test",
        name: "Quick Discouraged Focused Test",
        description: "Discouraged focused test. Other tests won't run while this one is focused.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedFocusedTestRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let dict = file.structureDictionary
        let testClasses = dict.substructure.filter {
            return $0.inheritedTypes.contains("QuickSpec") &&
                $0.declarationKind == .class
        }

        let specDeclarations = testClasses.flatMap { classDict in
            return classDict.substructure.filter {
                return $0.name == "spec()" && $0.enclosedVarParameters.isEmpty &&
                    $0.declarationKind == .functionMethodInstance &&
                    $0.enclosedSwiftAttributes.contains(.override)
            }
        }

        return specDeclarations.flatMap {
            validate(file: file, dictionary: $0)
        }
    }

    private func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }

    private func validate(file: SwiftLintFile,
                          kind: SwiftExpressionKind,
                          dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let name = dictionary.name,
            let offset = dictionary.offset,
            QuickFocusedCallKind(rawValue: name) != nil else { return [] }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}

private enum QuickFocusedCallKind: String {
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike
}
