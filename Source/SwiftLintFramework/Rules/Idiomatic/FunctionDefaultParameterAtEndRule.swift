import SourceKittenFramework

public struct FunctionDefaultParameterAtEndRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_default_parameter_at_end",
        name: "Function Default Parameter at End",
        description: "Prefer to locate parameters with defaults toward the end of the parameter list.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func foo(baz: String, bar: Int = 0) {}",
            "func foo(x: String, y: Int = 0, z: CGFloat = 0) {}",
            "func foo(bar: String, baz: Int = 0, z: () -> Void) {}",
            "func foo(bar: String, z: () -> Void, baz: Int = 0) {}",
            "func foo(bar: Int = 0) {}",
            "func foo() {}",
            """
            class A: B {
              override func foo(bar: Int = 0, baz: String) {}
            """,
            "func foo(bar: Int = 0, completion: @escaping CompletionHandler) {}",
            """
            func foo(a: Int, b: CGFloat = 0) {
              let block = { (error: Error?) in }
            }
            """
        ],
        triggeringExamples: [
            "↓func foo(bar: Int = 0, baz: String) {}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            !dictionary.enclosedSwiftAttributes.contains(.override) else {
                return []
        }

        let isNotClosure = { !self.isClosureParameter(dictionary: $0) }
        let params = dictionary.enclosedVarParameters.filter(isNotClosure).filter { param in
            guard let paramOffset = param.offset else {
                return false
            }

            return paramOffset < bodyOffset
        }

        guard !params.isEmpty else {
            return []
        }

        let containsDefaultValue = { self.isDefaultParameter(file: file, dictionary: $0) }
        let defaultParams = params.filter(containsDefaultValue)
        guard !defaultParams.isEmpty else {
            return []
        }

        let lastParameters = params.suffix(defaultParams.count)
        let lastParametersWithDefaultValue = lastParameters.filter(containsDefaultValue)

        guard lastParameters.count != lastParametersWithDefaultValue.count else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClosureParameter(dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let typeName = dictionary.typeName else {
            return false
        }

        return typeName.contains("->") || typeName.contains("@escaping")
    }

    private func isDefaultParameter(file: File, dictionary: [String: SourceKitRepresentable]) -> Bool {
        let contents = file.contents.bridge()
        guard let offset = dictionary.offset, let length = dictionary.length,
            let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                return false
        }

        return regex("=").firstMatch(in: file.contents, options: [], range: range) != nil
    }
}
