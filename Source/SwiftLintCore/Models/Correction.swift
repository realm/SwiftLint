import Foundation

/// A value describing a SwiftLint violation that was corrected.
public struct Correction: Equatable, Sendable {
    /// The name of the rule that was corrected.
    public let ruleName: String
    /// The path to the file that was corrected.
    public let filePath: URL?
    /// The number of corrections that were made.
    public let numberOfCorrections: Int

    /// The console-printable description for this correction.
    public var consoleDescription: String {
        let times = numberOfCorrections == 1 ? "time" : "times"
        return "\(filePath?.relativeDisplayPath ?? "<nopath>"): Corrected \(ruleName) \(numberOfCorrections) \(times)"
    }

    /// Memberwise initializer.
    ///
    /// - parameter ruleName: The name of the rule that was corrected.
    /// - parameter filePath: The path to the file that was corrected.
    /// - parameter numberOfCorrections: The number of corrections that were made.
    public init(ruleName: String, filePath: URL?, numberOfCorrections: Int) {
        self.ruleName = ruleName
        self.filePath = filePath
        self.numberOfCorrections = numberOfCorrections
    }
}
