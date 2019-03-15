import Foundation
import SourceKittenFramework

public struct CallSuperOnlyRule: SubstitutionCorrectableASTRule,
ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    static let nonTriggeringExamples = [
        """
        override func viewDidDisappear(_ animated: Bool) {
            childViewController.viewDidDisappear(animated)
        }
        """,
        """
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            print("View controller did disappear")
        }
        """,
        """
        public override init() {
            super.init()
        }
        """,
        """
        override func setUp() {
            super.setUp()
            urlString = "https://httpbin.org/basic-auth"
        }
        """
    ].map(wrapInClass)

    static let triggeringExamples = [
        """
        override func a(){/*comment*/super.a()}
        """,
        """
        override func viewDidLoad() {
            super.viewDidLoad()

            // Do any additional setup after loading the view.
        }
        """,
        """
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        """,
        """
        override func becomeFirstResponder() -> Bool {
            return super.becomeFirstResponder()
        }
        """,
        """
        internal
        class
        override
        func setUp() {
            super.setUp()
        }
        """
    ].map(wrapInClass)

    static let corrections = Dictionary(uniqueKeysWithValues:
        CallSuperOnlyRule.triggeringExamples.map { ($0, wrapInClass(" ")) })

    public static let description = RuleDescription(
        identifier: "call_super_only",
        name: "Call Super Only",
        description: "Methods that don't do anything but call `super` can be removed",
        kind: .lint,
        nonTriggeringExamples: CallSuperOnlyRule.nonTriggeringExamples,
        triggeringExamples: CallSuperOnlyRule.triggeringExamples,
        corrections: CallSuperOnlyRule.corrections
    )

    public func violationRanges(in file: File, kind: SwiftDeclarationKind,
                                dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        let overridingKinds: [SwiftDeclarationKind] = [
            .functionMethodInstance,
            .functionMethodClass,
            .functionMethodStatic
        ]
        guard overridingKinds.contains(kind),
            dictionary.enclosedSwiftAttributes.contains(.override),
            !dictionary.enclosedSwiftAttributes.contains(.public),
            file.onlyCallsSuper(dictionary),
            let offset = dictionary.offset,
            let length = dictionary.length
            else { return [] }

        let startIndex = dictionary.swiftAttributes
            .compactMap { $0.offset }
            .min() ?? offset
        let endIndex = offset + length

        return [NSRange(startIndex...endIndex)]
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: $0.location)
            )
        }
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        let range = file.contents.bridge()
            .byteRangeToNSRange(start: violationRange.location, length: violationRange.length)!
        return (range, " \n")
    }
}

private extension File {
    func onlyCallsSuper(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        if let name = dictionary.name?.split(separator: "(").first,
            dictionary.substructure.count == 1,
            let methodCall = dictionary.substructure.first,
            methodCall.name == "super.\(name)",
            !hasAssignmentInBody(dictionary) {
            return true
        } else {
            return false
        }
    }

    private func hasAssignmentInBody(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let range = contents.bridge().byteRangeToNSRange(start: bodyOffset, length: bodyLength)
            else { return false }

        let body = contents.substring(from: range.location, length: range.length)
        let assignmentOperators = ["=", "*=", "/=", "%=", "+=", "-=",
                                   "<<=", ">>=", "&=", "|=", "^="]

        return assignmentOperators.contains(where: body.contains)
    }
}

private func wrapInClass(_ string: String) -> String {
    return """
    class ViewController: UIViewController {
    \(string
        .split(separator: "\n")
        .map { "    " + $0 }
        .joined(separator: "\n")
    )
    }
    """
}
