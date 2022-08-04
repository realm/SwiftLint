import SourceKittenFramework

public struct NSObjectPreferIsEqualRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nsobject_prefer_isequal",
        name: "NSObject Prefer isEqual",
        description: "NSObject subclasses should implement isEqual instead of ==.",
        kind: .lint,
        nonTriggeringExamples: NSObjectPreferIsEqualRuleExamples.nonTriggeringExamples,
        triggeringExamples: NSObjectPreferIsEqualRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return objcVisibleClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func objcVisibleClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary

        return dict.substructure.filter { dictionary in
            guard dictionary.declarationKind == .class
            else { return false }
            let isDirectNSObjectSubclass = dictionary.inheritedTypes.contains("NSObject")
            let isMarkedObjc = dictionary.enclosedSwiftAttributes.contains(.objc)
            return isDirectNSObjectSubclass || isMarkedObjc
        }
    }

    private func violations(in file: SwiftLintFile,
                            for dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let typeName = dictionary.name else { return [] }
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                isDoubleEqualsMethod(subDictionary, onType: typeName),
                let offset = subDictionary.offset
            else { return nil }
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isDoubleEqualsMethod(_ method: SourceKittenDictionary,
                                      onType typeName: String) -> Bool {
        guard
            let kind = method.declarationKind,
            let name = method.name,
            kind == .functionMethodStatic,
            name == "==(_:_:)",
            areAllArguments(toMethod: method, ofType: typeName)
        else { return false }
        return true
    }

    private func areAllArguments(toMethod method: SourceKittenDictionary,
                                 ofType typeName: String) -> Bool {
        return method.enclosedVarParameters.allSatisfy { param in
            param.typeName == typeName
        }
    }
}
