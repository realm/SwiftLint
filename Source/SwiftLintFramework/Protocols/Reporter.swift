public protocol Reporter: CustomStringConvertible {
    static var identifier: String { get }
    static var isRealtime: Bool { get }

    static func generateReport(_ violations: [StyleViolation]) -> String
}

public func reporterFrom(identifier: String) -> Reporter.Type {
    switch identifier {
    case XcodeReporter.identifier:
        return XcodeReporter.self
    case JSONReporter.identifier:
        return JSONReporter.self
    case CSVReporter.identifier:
        return CSVReporter.self
    case CheckstyleReporter.identifier:
        return CheckstyleReporter.self
    case JUnitReporter.identifier:
        return JUnitReporter.self
    case HTMLReporter.identifier:
        return HTMLReporter.self
    case EmojiReporter.identifier:
        return EmojiReporter.self
    case SonarQubeReporter.identifier:
        return SonarQubeReporter.self
    case MarkdownReporter.identifier:
        return MarkdownReporter.self
    default:
        queuedFatalError("no reporter with identifier '\(identifier)' available.")
    }
}
