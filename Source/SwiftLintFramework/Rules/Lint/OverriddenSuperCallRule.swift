import SourceKittenFramework

public struct OverriddenSuperCallRule: ConfigurationProviderRule, ASTRule, OptInRule {
    public var configuration = OverriddenSuperCallConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "overridden_super_call",
        name: "Overridden methods call super",
        description: "Some overridden methods should always call super",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {
                    super.viewWillAppear(animated)
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {
                    self.method1()
                    super.viewWillAppear(animated)
                    self.method2()
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func loadView() {
                }
            }
            """),
            Example("""
            class Some {
                func viewWillAppear(_ animated: Bool) {
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewDidLoad() {
                defer {
                    super.viewDidLoad()
                    }
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {↓
                    //Not calling to super
                    self.method()
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {↓
                    super.viewWillAppear(animated)
                    //Other code
                    super.viewWillAppear(animated)
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func didReceiveMemoryWarning() {↓
                }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.bodyOffset,
            let name = dictionary.name,
            kind == .functionMethodInstance,
            configuration.resolvedMethodNames.contains(name),
            dictionary.enclosedSwiftAttributes.contains(.override)
        else { return [] }

        let callsToSuper = dictionary.extractCallsToSuper(methodName: name)

        if callsToSuper.isEmpty {
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Method '\(name)' should call to super function")]
        } else if callsToSuper.count > 1 {
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Method '\(name)' should call to super only once")]
        }
        return []
    }
}
