import SourceKittenFramework

public struct DeinitRequiredRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "deinit_required",
        name: "Deinit Required",
        description: "Classes should have an explicit deinit method.",
        kind: .style,
        nonTriggeringExamples: [
            """
            class Apple {
                deinit { }
            }
            """,
            "enum Banana { }",
            "protocol Cherry { }",
            "struct Damson { }"
        ],
        triggeringExamples: [
            "↓class Apple { }",
            "↓class Banana: NSObject, Equatable { }",
            """
            ↓class Cherry {
                // deinit { }
            }
            """,
            """
            ↓class Damson {
                func deinitialize() { }
            }
            """,
            """
            class Outer {
                func hello() -> String { return "outer" }
                deinit { }

                ↓class Inner {
                    func hello() -> String { return "inner" }
                }
            }
            """
        ]
    )

    public init() {}

    public func validate(file: File) -> [StyleViolation] {
        let classCollector = NamespaceCollector(dictionary: file.structure.dictionary)
        let classes = classCollector.findAllElements(of: [.class])

        let violations: [StyleViolation] = classes.compactMap { element in
            guard let offset = element.dictionary.offset else {
                return nil
            }

            let methodCollector = NamespaceCollector(dictionary: element.dictionary)
            let methods = methodCollector.findAllElements(of: [.functionMethodInstance])

            let containsDeinit = methods.contains {
                $0.name == "deinit"
            }

            if containsDeinit {
                return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }

        return violations
    }
}
