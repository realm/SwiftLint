import SourceKittenFramework

public struct ExpiringTodoRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public static let description = RuleDescription(
        identifier: "expiring_todo",
        name: "ExpiringTodo",
        description: "TODOs and FIXMEs should be resolved prior to their expiry date.",
        kind: .lint,
        nonTriggeringExamples: [
            "// notaTODO:\n",
            "// notaFIXME:\n",
            "// ↓TODO: [12/31/9999]\n",
            "// ↓TODO(note)\n",
            "// ↓FIXME(note)\n",
            "/* ↓FIXME: */\n",
            "/* ↓TODO: */\n",
            "/** ↓FIXME: */\n",
            "/** ↓TODO: */\n"
        ],
        triggeringExamples: [
            "// ↓TODO: [10/14/2019]\n",
            "// ↓FIXME: [10/14/2019]\n"
        ]
    )

    public var configuration = ExpiringTodoConfiguration(
        approachingExpirySeverity: .init(.warning),
        expiredSeverity: .init(.error)
    )

    private var calendar: Calendar = .current

    public init() {}

    public func validate(file: File) -> [StyleViolation] {
        // swiftlint:disable line_length
        let regex = "\\b(?:TODO|FIXME)(?::|\\b)(?:.*)\\\(configuration.dateDelimiters.opening)(\\d{2,4}\\\(configuration.dateSeparator)\\d{2}\\\(configuration.dateSeparator)\\d{2,4})\\\(configuration.dateDelimiters.closing)"
        // swiftlint:enable line_length

        return file.matchesAndSyntaxKinds(matching: regex).compactMap { checkingResult, syntaxKinds in
            guard
                syntaxKinds.allSatisfy({ $0.isCommentLike }),
                checkingResult.numberOfRanges > 1,
                case let range = checkingResult.range(at: 1),
                let date = expiryDate(file: file, range: range),
                let violationLevel = self.violationLevel(for: date),
                let severity = self.severity(for: violationLevel) else {
                return nil
            }

            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: severity,
                location: Location(file: file, characterOffset: range.location),
                reason: violationLevel.reason
            )
        }
    }

    private func expiryDate(file: File, range: NSRange) -> Date? {
        // Get the date of expiry
        let expiryDateString = file.contents.bridge()
            .substring(with: range)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.dateFormat = configuration.dateFormat

        return formatter.date(from: expiryDateString)
    }

    private func severity(for violationLevel: ViolationLevel) -> ViolationSeverity? {
        switch violationLevel {
        case .approaching:
            return configuration.approachingExpirySeverity.severity
        case .expired:
            return configuration.expiredSeverity.severity
        }
    }

    private func violationLevel(for date: Date) -> ViolationLevel? {
        guard date.isEarlierThanToday else {
            return .expired
        }
        guard let approachingDate = calendar.date(
            byAdding: .day,
            value: -configuration.approachingExpiryThreshold,
            to: date) else {
                return nil
        }
        return date.isDateInDaysBefore(otherDate: approachingDate) ?
            nil :
            .approaching
    }
}

private enum ViolationLevel {
    case approaching
    case expired

    var reason: String {
        switch self {
        case .approaching:
            return "TODO/FIXME is approaching its expiry"
        case .expired:
            return "TODO/FIXME has expired and must be resolved"
        }
    }
}

private extension Date {
    var isEarlierThanToday: Bool {
        isDateInDaysBefore(otherDate: .init())
    }

    /// Returns `false` if date falls after (or in same day as) otherDate
    func isDateInDaysBefore(otherDate: Date) -> Bool {
        self < otherDate && !Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
}
