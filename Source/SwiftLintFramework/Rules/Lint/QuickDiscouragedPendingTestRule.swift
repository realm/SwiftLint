import SourceKittenFramework

public struct QuickDiscouragedPendingTestRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_pending_test",
        name: "Quick Discouraged Pending Test",
        description: "Discouraged pending test. This test won't run while it's marked as pending.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedPendingTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedPendingTestRuleExamples.triggeringExamples
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
            QuickPendingCallKind(rawValue: name) != nil else { return [] }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}

private enum QuickPendingCallKind: String {
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
}
