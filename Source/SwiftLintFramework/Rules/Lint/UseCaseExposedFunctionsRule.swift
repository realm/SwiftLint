import SourceKittenFramework

struct UseCaseExposedFunctionsRule: ASTRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    let message: String = "A UseCase should only expose one public function"

    static let description = RuleDescription(
        identifier: "usecase_exposed_functions",
        name: "UseCaseExposedFunctionsRule",
        description: "A UseCase should only expose one public function",
        kind: .style,
        nonTriggeringExamples: UseCaseExposedFunctionsRuleExamples.nonTriggeringExamples,
        triggeringExamples: UseCaseExposedFunctionsRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
                    // Only proceed to check functional logic files.
        guard dictionary.name?.hasSuffix("Logic") ?? false || dictionary.name?.hasSuffix("UseCase") ?? false,
              dictionary.substructure.isNotEmpty
        else { return [] }

        let classFunctions: [SourceKittenDictionary] = dictionary.substructure.filter {
            $0.accessibility != .private && isFunction(structure: $0)
        }

        // The same rule applies to both classes and struct as you need an initializer function for your logic construct
        if (kind == .class || kind == .struct) && classFunctions.count > 2 {
            return [
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file,
                                                  byteOffset: ByteCount(classFunctions[2].offset?.value ?? 1)),
                               reason: message)
            ]
        }
        // This applies to only protocols are they cannot be initialized
        if kind == .protocol && classFunctions.count > 1 {
            return [
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file,
                                                  byteOffset: ByteCount(classFunctions[1].offset?.value ?? 1)),
                               reason: message)
            ]
        }
        return []
    }

    private func isFunction(structure: SourceKittenDictionary) -> Bool {
        let kind = structure.kind
        return kind == nil ? false : kind == "source.lang.swift.decl.function.method.instance"
    }
}

internal struct UseCaseExposedFunctionsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        struct MyView: View {
            var body: some View {
                Image(decorative: "my-image")
            }
        }
        """),
        Example("""
        class MyViewModel: ViewModel {
            var state: State = State.empty()
        }
        """),
        Example("""
        protocol LogicalProtocol {
            func receive() -> Bool
        }
        """),
        Example("""
        public class MyUseCase {
            public init() {}

            public func callAsFunction() -> AnyPublisher<Void, Never> {}

            private func computeInput() {}
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            private func get(fire: String) -> Int {
                return 35
            }
            func callAsFunction() -> String {
                return "call"
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        public protocol MyLogic {
            func getSomething() -> String
            func callAsFunction() -> AnyPublisher<Void, Never>
        }
        """),
        Example("""
        public struct MyLogic {
            public init() {}

            public func get() -> Int {
                return 45
            }
            public func callAsFunction() -> String {
                return ""
            }
        }
        """),
        Example("""
        public class MyLogic {
            public init() {}

            public func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """)
    ]
}
