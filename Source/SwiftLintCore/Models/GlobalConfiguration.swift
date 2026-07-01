/// Global configuration values made available to rules during linting.
public struct GlobalConfiguration: Hashable, Sendable {
    /// The indentation style rules should assume when checking code.
    public let indentation: IndentationStyle

    /// Creates a global configuration value.
    public init(indentation: IndentationStyle) {
        self.indentation = indentation
    }
}
