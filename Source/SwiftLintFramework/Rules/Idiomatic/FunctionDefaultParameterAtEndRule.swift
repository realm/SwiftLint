import SourceKittenFramework

public struct FunctionDefaultParameterAtEndRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_default_parameter_at_end",
        name: "Function Default Parameter at End",
        description: "Prefer to locate parameters with defaults toward the end of the parameter list.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("func foo(baz: String, bar: Int = 0) {}"),
            Example("func foo(x: String, y: Int = 0, z: CGFloat = 0) {}"),
            Example("func foo(bar: String, baz: Int = 0, z: () -> Void) {}"),
            Example("func foo(bar: String, z: () -> Void, baz: Int = 0) {}"),
            Example("func foo(bar: Int = 0) {}"),
            Example("func foo() {}"),
            Example("""
            class A: B {
              override func foo(bar: Int = 0, baz: String) {}
            """),
            Example("func foo(bar: Int = 0, completion: @escaping CompletionHandler) {}"),
            Example("""
            func foo(a: Int, b: CGFloat = 0) {
              let block = { (error: Error?) in }
            }
            """),
            Example("""
            func foo(a: String, b: String? = nil,
                     c: String? = nil, d: @escaping AlertActionHandler = { _ in }) {}
            """)
        ],
        triggeringExamples: [
            Example("↓func foo(bar: Int = 0, baz: String) {}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            !dictionary.enclosedSwiftAttributes.contains(.override) else {
                return []
        }

        let isNotClosure = { !self.isClosureParameter(dictionary: $0) }
        let params = dictionary.substructure
            .flatMap { subDict -> [SourceKittenDictionary] in
                guard subDict.declarationKind == .varParameter else {
                    return []
                }

                return [subDict]
            }
            .filter(isNotClosure)
            .filter { param in
                guard let paramOffset = param.offset else {
                    return false
                }

                return paramOffset < bodyOffset
            }

        guard params.isNotEmpty else {
            return []
        }

        let containsDefaultValue = { self.isDefaultParameter(file: file, dictionary: $0) }
        let defaultParams = params.filter(containsDefaultValue)
        guard defaultParams.isNotEmpty else {
            return []
        }

        let lastParameters = params.suffix(defaultParams.count)
        let lastParametersWithDefaultValue = lastParameters.filter(containsDefaultValue)

        guard lastParameters.count != lastParametersWithDefaultValue.count else {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClosureParameter(dictionary: SourceKittenDictionary) -> Bool {
        guard let typeName = dictionary.typeName else {
            return false
        }

        return typeName.contains("->") || typeName.contains("@escaping")
    }

    private func isDefaultParameter(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> Bool {
        guard let range = dictionary.byteRange.flatMap(file.stringView.byteRangeToNSRange) else {
            return false
        }

        return regex("=").firstMatch(in: file.contents, options: [], range: range) != nil
    }
}
