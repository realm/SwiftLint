import SourceKittenFramework

struct QuickDiscouragedCallRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "quick_discouraged_call",
        name: "Quick Discouraged Call",
        description: "Discouraged call inside 'describe' and/or 'context' block.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedCallRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedCallRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let dict = file.structureDictionary
        let testClasses = dict.substructure.filter {
            $0.inheritedTypes.isNotEmpty &&
                $0.declarationKind == .class
        }

        let specDeclarations = testClasses.flatMap { classDict in
            classDict.substructure.filter { structure in
                   structure.name == "spec()"
                && structure.enclosedVarParameters.isEmpty
                && [.functionMethodInstance, .functionMethodStatic].contains(structure.declarationKind)
                && structure.enclosedSwiftAttributes.contains(.override)
            }
        }

        return specDeclarations.flatMap {
            validate(file: file, dictionary: $0)
        }
    }

    private func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }

    private func validate(file: SwiftLintFile,
                          kind: SwiftExpressionKind,
                          dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // is it a call to a restricted method?
        guard
            kind == .call,
            let name = dictionary.name,
            let kindName = QuickCallKind(rawValue: name),
            QuickCallKind.restrictiveKinds.contains(kindName)
            else { return [] }

        return violationOffsets(in: dictionary.enclosedArguments).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0),
                           reason: "Discouraged call inside a '\(name)' block")
        }
    }

    private func violationOffsets(in substructure: [SourceKittenDictionary]) -> [ByteCount] {
        substructure.flatMap { dictionary -> [ByteCount] in
            let substructure = dictionary.substructure.flatMap { dict -> [SourceKittenDictionary] in
                if dict.expressionKind == .closure {
                    return dict.substructure
                }
                return [dict]
            }

            return substructure.flatMap(toViolationOffsets)
        }
    }

    private func toViolationOffsets(dictionary: SourceKittenDictionary) -> [ByteCount] {
        guard
            dictionary.kind != nil,
            let offset = dictionary.offset
            else { return [] }

        if dictionary.expressionKind == .call,
            let name = dictionary.name, QuickCallKind(rawValue: name) == nil {
            return [offset]
        }

        guard dictionary.expressionKind != .call else { return [] }

        return dictionary.substructure.compactMap(toViolationOffset)
    }

    private func toViolationOffset(dictionary: SourceKittenDictionary) -> ByteCount? {
        guard
            let name = dictionary.name,
            let offset = dictionary.offset,
            dictionary.expressionKind == .call,
            QuickCallKind(rawValue: name) == nil
            else { return nil }

        return offset
    }
}

private enum QuickCallKind: String {
    case describe
    case context
    case sharedExamples
    case itBehavesLike
    case aroundEach
    case beforeEach
    case justBeforeEach
    case beforeSuite
    case afterEach
    case afterSuite
    case it // swiftlint:disable:this identifier_name
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike

    static let restrictiveKinds: Set<QuickCallKind> = [
        .describe, .fdescribe, .xdescribe, .context, .fcontext, .xcontext, .sharedExamples
    ]
}
