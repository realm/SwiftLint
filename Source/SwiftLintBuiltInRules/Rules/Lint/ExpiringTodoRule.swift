import Foundation
import SourceKittenFramework

struct ExpiringTodoRule: ConfigurationProviderRule, OptInRule {
    enum ExpiryViolationLevel {
        case approachingExpiry
        case expired
        case badFormatting

        var reason: String {
            switch self {
            case .approachingExpiry:
                return "TODO/FIXME is approaching its expiry and should be resolved soon"
            case .expired:
                return "TODO/FIXME has expired and must be resolved"
            case .badFormatting:
                return "Expiring TODO/FIXME is incorrectly formatted"
            }
        }
    }

    static let description = RuleDescription(
        identifier: "expiring_todo",
        name: "Expiring Todo",
        description: "TODOs and FIXMEs should be resolved prior to their expiry date.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// notaTODO:\n"),
            Example("// notaFIXME:\n"),
            Example("// TODO: [12/31/9999]\n"),
            Example("// TODO(note)\n"),
            Example("// FIXME(note)\n"),
            Example("/* FIXME: */\n"),
            Example("/* TODO: */\n"),
            Example("/** FIXME: */\n"),
            Example("/** TODO: */\n")
        ],
        triggeringExamples: [
            Example("// TODO: [↓10/14/2019]\n"),
            Example("// FIXME: [↓10/14/2019]\n"),
            Example("// FIXME: [↓1/14/2019]\n"),
            Example("// FIXME: [↓10/14/2019]\n"),
            Example("// TODO: [↓9999/14/10]\n")
        ].skipWrappingInCommentTests()
    )

    var configuration: ExpiringTodoConfiguration = .init()

    init() {}

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let regex = #"""
        \b(?:TODO|FIXME)(?::|\b)(?:(?!\b(?:TODO|FIXME)(?::|\b)).)*?\#
        \\#(configuration.dateDelimiters.opening)\#
        (\d{1,4}\\#(configuration.dateSeparator)\d{1,4}\\#(configuration.dateSeparator)\d{1,4})\#
        \\#(configuration.dateDelimiters.closing)
        """#

        return file.matchesAndSyntaxKinds(matching: regex).compactMap { checkingResult, syntaxKinds in
            guard
                syntaxKinds.allSatisfy({ $0.isCommentLike }),
                checkingResult.numberOfRanges > 1,
                case let range = checkingResult.range(at: 1),
                let violationLevel = self.violationLevel(for: expiryDate(file: file, range: range)),
                let severity = self.severity(for: violationLevel) else {
                return nil
            }

            return StyleViolation(
                ruleDescription: Self.description,
                severity: severity,
                location: Location(file: file, characterOffset: range.location),
                reason: violationLevel.reason
            )
        }
    }

    private func expiryDate(file: SwiftLintFile, range: NSRange) -> Date? {
        let expiryDateString = file.contents.bridge()
            .substring(with: range)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.dateFormat = configuration.dateFormat

        return formatter.date(from: expiryDateString)
    }

    private func severity(for violationLevel: ExpiryViolationLevel) -> ViolationSeverity? {
        switch violationLevel {
        case .approachingExpiry:
            return configuration.approachingExpirySeverity.severity
        case .expired:
            return configuration.expiredSeverity.severity
        case .badFormatting:
            return configuration.badFormattingSeverity.severity
        }
    }

    private func violationLevel(for expiryDate: Date?) -> ExpiryViolationLevel? {
        guard let expiryDate = expiryDate else {
            return .badFormatting
        }
        guard expiryDate.isAfterToday else {
            return .expired
        }
        guard let approachingDate = Calendar.current.date(
            byAdding: .day,
            value: -configuration.approachingExpiryThreshold,
            to: expiryDate) else {
                return nil
        }
        return approachingDate.isAfterToday ?
            nil :
            .approachingExpiry
    }
}

private extension Date {
    var isAfterToday: Bool {
        return Calendar.current.compare(.init(), to: self, toGranularity: .day) == .orderedAscending
    }
}
