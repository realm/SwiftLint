import SourceKittenFramework

/// Rule to require all classes to have a deinit method
///
/// An example of when this is useful is if the project does allocation tracking
/// of objects and the deinit should print a message or remove its instance from a
/// list of allocations. Even having an empty deinit method is useful to provide
/// a place to put a breakpoint when chasing down leaks.
public struct RequiredDeinitRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "required_deinit",
        name: "Required Deinit",
        description: "Classes should have an explicit deinit method.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Apple {
                deinit { }
            }
            """),
            Example("enum Banana { }"),
            Example("protocol Cherry { }"),
            Example("struct Damson { }"),
            Example("""
            class Outer {
                deinit { print("Deinit Outer") }
                class Inner {
                    deinit { print("Deinit Inner") }
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓class Apple { }"),
            Example("↓class Banana: NSObject, Equatable { }"),
            Example("""
            ↓class Cherry {
                // deinit { }
            }
            """),
            Example("""
            ↓class Damson {
                func deinitialize() { }
            }
            """),
            Example("""
            class Outer {
                func hello() -> String { return "outer" }
                deinit { }
                ↓class Inner {
                    func hello() -> String { return "inner" }
                }
            }
            """),
            Example("""
            ↓class Outer {
                func hello() -> String { return "outer" }
                class Inner {
                    func hello() -> String { return "inner" }
                    deinit { }
                }
            }
            """)
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .class,
            let offset = dictionary.offset else {
                return []
        }

        let methodCollector = NamespaceCollector(dictionary: dictionary)
        let methods = methodCollector.findAllElements(of: [.functionMethodInstance])

        let containsDeinit = methods.contains {
            $0.name == "deinit"
        }

        if containsDeinit {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
