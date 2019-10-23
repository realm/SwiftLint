import SourceKittenFramework

public struct NSObjectPreferIsEqualRule: Rule, ConfigurationProviderRule, AutomaticTestableRule {
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

    public func validate(file: File) -> [StyleViolation] {
        return objcVisibleClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func objcVisibleClasses(in file: File) -> [SourceKittenDictionary] {
        let dict = SourceKittenDictionary(value: file.structure.dictionary)

        return dict.substructure.filter { dictionary in
            guard
                let kind = dictionary.kind,
                SwiftDeclarationKind(rawValue: kind) == .class
            else { return false }
            let isDirectNSObjectSubclass = dictionary.inheritedTypes.contains("NSObject")
            let isMarkedObjc = dictionary.enclosedSwiftAttributes.contains(.objc)
            return isDirectNSObjectSubclass || isMarkedObjc
        }
    }

    private func violations(in file: File,
                            for dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let typeName = dictionary.name else { return [] }
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                isDoubleEqualsMethod(subDictionary, onType: typeName),
                let offset = subDictionary.offset
            else { return nil }
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isDoubleEqualsMethod(_ method: SourceKittenDictionary,
                                      onType typeName: String) -> Bool {
        guard
            let kind = method.kind.flatMap(SwiftDeclarationKind.init),
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
