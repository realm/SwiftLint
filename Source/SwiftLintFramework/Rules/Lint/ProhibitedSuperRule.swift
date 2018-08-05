import SourceKittenFramework

public struct ProhibitedSuperRule: ConfigurationProviderRule, ASTRule, OptInRule, AutomaticTestableRule {
    public var configuration = ProhibitedSuperConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_super_call",
        name: "Prohibited calls to super",
        description: "Some methods should not call super",
        kind: .lint,
        nonTriggeringExamples: [
            """
            class VC: UIViewController {
                override func loadView() {
                }
            }
            """,
            """
            class NSView {
                func updateLayer() {
                    self.method1()
                }
            }
            """,
            """
            public class FileProviderExtension: NSFileProviderExtension {
                override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
                    guard let identifier = persistentIdentifierForItem(at: url) else {
                        completionHandler(NSFileProviderError(.noSuchItem))
                        return
                    }
                }
            }
            """
        ],
        triggeringExamples: [
            """
            class VC: UIViewController {
                override func loadView() {↓
                    super.loadView()
                }
            }
            """,
            """
            class VC: NSFileProviderExtension {
                override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {↓
                    self.method1()
                    super.providePlaceholder(at:url, completionHandler: completionHandler)
                }
            }
            """,
            """
            class VC: NSView {
                override func updateLayer() {↓
                    self.method1()
                    super.updateLayer()
                    self.method2()
                }
            }
            """,
            """
            class VC: NSView {
                override func updateLayer() {↓
                    defer {
                        super.updateLayer()
                    }
                }
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.bodyOffset,
            let name = dictionary.name,
            kind == .functionMethodInstance,
            configuration.resolvedMethodNames.contains(name),
            dictionary.enclosedSwiftAttributes.contains(.override),
            !dictionary.extractCallsToSuper(methodName: name).isEmpty
            else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset),
                               reason: "Method '\(name)' should not call to super function")]
    }
}
