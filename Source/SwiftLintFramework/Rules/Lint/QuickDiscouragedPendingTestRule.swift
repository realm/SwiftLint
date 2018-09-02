import SourceKittenFramework

public struct QuickDiscouragedPendingTestRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
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

    public func validate(file: File) -> [StyleViolation] {
        let testClasses = file.structure.dictionary.substructure.filter {
            return $0.inheritedTypes.contains("QuickSpec") &&
                $0.kind.flatMap(SwiftDeclarationKind.init) == .class
        }

        let specDeclarations = testClasses.flatMap { classDict in
            return classDict.substructure.filter {
                return $0.name == "spec()" && $0.enclosedVarParameters.isEmpty &&
                    $0.kind.flatMap(SwiftDeclarationKind.init) == .functionMethodInstance &&
                    $0.enclosedSwiftAttributes.contains(.override)
            }
        }

        return specDeclarations.flatMap {
            validate(file: file, dictionary: $0)
        }
    }

    private func validate(file: File, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict)
            }

            return violations
        }
    }

    private func validate(file: File,
                          kind: SwiftExpressionKind,
                          dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let name = dictionary.name,
            let offset = dictionary.offset,
            QuickPendingCallKind(rawValue: name) != nil else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
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
