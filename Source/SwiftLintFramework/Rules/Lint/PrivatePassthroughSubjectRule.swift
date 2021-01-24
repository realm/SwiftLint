import SourceKittenFramework

public struct PrivatePassthroughSubjectRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "private_passthrough_subject",
        name: "Private PassthroughSubject",
        description: "PassthroughSubjects should be private.",
        kind: .lint,
        nonTriggeringExamples: PrivatePassthroughSubjectRuleExamples.nonTriggeringExamples,
        triggeringExamples: PrivatePassthroughSubjectRuleExamples.triggeringExamples
    )

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .varInstance,
            dictionary.accessibility?.isPrivate == false
        else {
            return []
        }

        let declarationViolation = declarationViolationOffset(
            dictionary: dictionary
        )

        let defaultValueViolation = defaultValueViolationOffset(
            file: file,
            dictionary: dictionary
        )

        let violations = [declarationViolation, defaultValueViolation]
            .compactMap { $0 }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }

        return violations
    }

    // MARK: - Private

    /// Looks for violations matching the format:
    ///
    /// * `let subject: PassthroughSubject<Bool, Never>`
    /// * `let subject: PassthroughSubject<Bool, Never> = .init()`
    ///
    private func declarationViolationOffset(dictionary: SourceKittenDictionary) -> ByteCount? {
        guard dictionary.typeName?.hasPrefix("PassthroughSubject") == true else {
            return nil
        }

        return dictionary.nameOffset
    }

    /// Looks for violations matching the format:
    ///
    /// * `let ↓subject = PassthroughSubject<Bool, Never>()`
    ///
    private func defaultValueViolationOffset(file: SwiftLintFile,
                                             dictionary: SourceKittenDictionary) -> ByteCount? {
        guard
            let offset = dictionary.offset,
            let length = dictionary.length,
            case let byteRange = ByteRange(location: offset, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange),
            file.match(pattern: "PassthroughSubject<(.*)>\\(\\)", range: range).isEmpty == false
        else {
            return nil
        }

        return dictionary.nameOffset
    }
}
