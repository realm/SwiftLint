internal struct DisallowDefaultParameterRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        // Public functions are allowed by default
        Example("public func foo(bar: Int = 0) {}"),
        Example("open func foo(bar: Int = 0) {}"),
        // No defaults — always fine
        Example("func foo(bar: Int) {}"),
        Example("private func foo(bar: Int) {}"),
        // Public init with default
        Example("public init(value: Int = 42) {}"),
        // Configuring only private — internal is fine
        Example(
            "func foo(bar: Int = 0) {}",
            configuration: ["disallowed_access_levels": ["private"]]
        ),
        Example(
            "internal func foo(bar: Int = 0) {}",
            configuration: ["disallowed_access_levels": ["private"]]
        ),
    ]

    static let triggeringExamples: [Example] = [
        // Private with default (default config disallows private + internal)
        Example("private func foo(bar: Int ↓= 0) {}"),
        // Internal (implicit) with default
        Example("func foo(bar: Int ↓= 0) {}"),
        // Explicit internal with default
        Example("internal func foo(bar: Int ↓= 0) {}"),
        // Multiple defaults
        Example("private func foo(bar: Int ↓= 0, baz: String ↓= \"\") {}"),
        // Init
        Example("private init(value: Int ↓= 42) {}"),
        // Package level when configured
        Example(
            "package func foo(bar: Int ↓= 0) {}",
            configuration: ["disallowed_access_levels": ["package"]]
        ),
        // Fileprivate
        Example(
            "fileprivate func foo(bar: Int ↓= 0) {}",
            configuration: ["disallowed_access_levels": ["fileprivate"]]
        ),
    ]
}
