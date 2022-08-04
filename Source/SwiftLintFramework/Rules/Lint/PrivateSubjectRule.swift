import SourceKittenFramework

public struct PrivateSubjectRule: ASTRule, OptInRule, ConfigurationProviderRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "private_subject",
        name: "Private Combine Subject",
        description: "Combine Subject should be private.",
        kind: .lint,
        nonTriggeringExamples: PrivateSubjectRuleExamples.nonTriggeringExamples,
        triggeringExamples: PrivateSubjectRuleExamples.triggeringExamples
    )

    private let subjectTypes: Set<String> = ["PassthroughSubject", "CurrentValueSubject"]

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
    /// * `let subject: CurrentValueSubject<Bool, Never>`
    /// * `let subject: CurrentValueSubject<String, Never> = .ini("toto")`
    ///
    /// - Returns: The violation offset.
    private func declarationViolationOffset(dictionary: SourceKittenDictionary) -> ByteCount? {
        guard
            let typeName = dictionary.typeName,
            subjectTypes.contains(where: typeName.hasPrefix) == true
        else {
            return nil
        }

        return dictionary.nameOffset
    }

    /// Looks for violations matching the format:
    ///
    /// * `let subject = PassthroughSubject<Bool, Never>()`
    /// * `let subject = CurrentValueSubject<String, Never>("toto")`
    ///
    /// - Returns: The violation offset.
    private func defaultValueViolationOffset(file: SwiftLintFile,
                                             dictionary: SourceKittenDictionary) -> ByteCount? {
        guard
            let offset = dictionary.offset,
            let length = dictionary.length,
            case let byteRange = ByteRange(location: offset, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange),
            case let subjects = subjectTypes.joined(separator: "|"),
            case let pattern = "(\(subjects))<(.+)>\\((.*)\\)",
            file.match(pattern: pattern, range: range).isEmpty == false
        else {
            return nil
        }

        return dictionary.nameOffset
    }
}
