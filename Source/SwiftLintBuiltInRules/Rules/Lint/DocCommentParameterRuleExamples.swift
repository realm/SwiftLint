struct DocCommentParameterRuleExamples {
    static let nonTriggeringExamples = [
        // Correctly documented function
        Example(code:
            """
            /// A function that does something.
            /// - Parameter value: The value to process.
            func process(value: Int) {}
            """),
        // Multiple parameters correctly documented
        Example(code:
            """
            /// Adds two numbers together.
            /// - Parameters:
            ///   - lhs: Left-hand side value.
            ///   - rhs: Right-hand side value.
            /// - Returns: The sum of `lhs` and `rhs`.
            func add(lhs: Int, rhs: Int) -> Int { lhs + rhs }
            """),
        // Function without parameters doesn't need parameter documentation
        Example(code:
            """
            /// Returns a greeting.
            func greet() -> String { "Hello" }
            """),
        // Function without doc comment is not validated
        Example(code:
            """
            func process(value: Int) {}
            """),
        // Correctly documented method with external and internal parameter names
        Example(code:
            """
            /// Updates the label.
            /// - Parameter text: The new text for the label.
            func updateLabel(with text: String) {}
            """),
        // Initializer with correctly documented parameters
        Example(code:
            """
            /// Creates a new instance.
            /// - Parameter value: The initial value.
            init(value: Int) {}
            """),
        // Subscript with correctly documented parameters
        Example(code:
            """
            /// Accesses the element at the specified index.
            /// - Parameter index: The index of the element.
            subscript(index: Int) -> Int { 0 }
            """),
        // Closure parameter documented
        Example(code:
            """
            /// Performs an operation.
            /// - Parameter completion: A closure called when complete.
            func perform(completion: () -> Void) {}
            """),
        // Underscore parameter name uses internal name
        Example(code:
            """
            /// Logs a message.
            /// - Parameter message: The message to log.
            func log(_ message: String) {}
            """),
        // Block doc comment
        Example(code:
            """
            /**
             * Processes the value.
             * - Parameter value: The value.
             */
            func process(value: Int) {}
            """),
        // Doc comment with only description (no parameter docs) for function without params
        Example(code:
            """
            /// This function does nothing.
            func doNothing() {}
            """),
        // validate_returns: returns doc present and function returns a value
        Example(code:
            """
            /// Computes a value.
            /// - Returns: The computed value.
            func compute() -> Int { 0 }
            """, configuration: ["validate_returns": true]),
        // validate_returns: no returns doc and function does not return a value
        Example(code:
            """
            /// Does something.
            func doSomething() {}
            """, configuration: ["validate_returns": true]),
        // validate_returns: returns doc present, Void return type — no violation
        Example(code:
            """
            /// Does something.
            func doSomethingVoid() -> Void {}
            """, configuration: ["validate_returns": true]),
        // validate_returns: returns doc present, Never return type — no violation
        Example(code:
            """
            /// Always fails.
            func fail() -> Never { fatalError() }
            """, configuration: ["validate_returns": true]),
        // validate_returns disabled (default) — missing returns doc is not flagged
        Example(code:
            """
            /// Computes a value.
            func computeNoDoc() -> Int { 0 }
            """),
        // validate_throws: throws doc present and function throws
        Example(code:
            """
            /// Parses the input.
            /// - Throws: `ParseError` if the input is invalid.
            func parse() throws {}
            """, configuration: ["validate_throws": true]),
        // validate_throws: no throws doc and function does not throw
        Example(code:
            """
            /// Does something safe.
            func safe() {}
            """, configuration: ["validate_throws": true]),
        // validate_throws: rethrows — throws doc is optional, both forms are fine
        Example(code:
            """
            /// Maps elements.
            /// - Parameter transform: A closure.
            /// - Throws: Rethrows errors from the closure.
            func map(transform: () throws -> Int) rethrows -> Int { try transform() }
            """, configuration: ["validate_throws": true]),
        Example(code:
            """
            /// Maps elements.
            /// - Parameter transform: A closure.
            func mapNoDoc(transform: () throws -> Int) rethrows -> Int { try transform() }
            """, configuration: ["validate_throws": true]),
        // validate_throws disabled (default) — missing throws doc is not flagged
        Example(code:
            """
            /// Parses the input.
            func parseNoDoc() throws {}
            """),
        // enforce_parameter_syntax: singular with 1 param — correct
        Example(code:
            """
            /// Does something.
            /// - Parameter value: The value.
            func single(value: Int) {}
            """, configuration: ["enforce_parameter_syntax": true]),
        // enforce_parameter_syntax: plural block with 2+ params — correct
        Example(code:
            """
            /// Does something.
            /// - Parameters:
            ///   - a: First.
            ///   - b: Second.
            func multi(a: Int, b: Int) {}
            """, configuration: ["enforce_parameter_syntax": true]),
        // enforce_parameter_syntax: no parameters — no violation
        Example(code:
            """
            /// Does something.
            func noParams() {}
            """, configuration: ["enforce_parameter_syntax": true]),
        // enforce_parameter_syntax disabled (default) — plural block with 1 param is fine
        Example(code:
            """
            /// Does something.
            /// - Parameters:
            ///   - value: The value.
            func singleDefault(value: Int) {}
            """),
        // Preceding doc comment must not bleed into the next declaration
        Example(code:
            """
            /// Logs a message.
            /// - Parameter message: The message.
            func log(_ message: String) {}

            // This is a plain (non-doc) comment.
            func unrelated(value: Int) {}
            """),
        // Parameters block followed by Returns section — Returns must not be parsed as a parameter
        Example(code:
            """
            /// Does something.
            /// - Parameters:
            ///   - value: The value.
            /// - Returns: The result.
            func process(value: Int) -> Int { value }
            """),
        // Parameters block followed by Throws section — Throws must exit the block correctly
        Example(code:
            """
            /// Parses input.
            /// - Parameters:
            ///   - input: The raw input.
            /// - Throws: `ParseError` on bad input.
            func parse(input: String) throws {}
            """),
        // Doubly-unnamed parameter (_ _:) has no documentable name — no violation
        Example(code:
            """
            /// Performs an action.
            func perform(_ _: Int) {}
            """),
        // Mix of normal and doubly-unnamed — only named params need docs
        Example(code:
            """
            /// Processes a value.
            /// - Parameter value: The value.
            func process(value: Int, _ _: String) {}
            """),
        // @discardableResult: missing Returns doc is not flagged even with validate_returns
        Example(code:
            """
            /// Computes a value whose result may be ignored.
            @discardableResult
            func compute() -> Int { 0 }
            """, configuration: ["validate_returns": true]),
        // Multi-line parameter description (continuation lines must not confuse the parser)
        Example(code:
            """
            /// Processes the input.
            /// - Parameters:
            ///   - value: A value that can be very long
            ///     and spans multiple lines of description.
            ///   - flag: A boolean flag.
            func process(value: Int, flag: Bool) {}
            """),
        // Note inside doc comment must not be mistaken for a parameter
        Example(code:
            """
            /// Sorts the collection.
            /// - Parameter collection: The collection to sort.
            /// - Note: Uses a stable sort algorithm.
            func sort(collection: [Int]) {}
            """),
        // Complexity callout inside Parameters block must not be mistaken for a parameter
        Example(code:
            """
            /// Sorts the collection.
            /// - Parameters:
            ///   - collection: The collection to sort.
            /// - Complexity: O(n log n).
            func sortInPlace(collection: [Int]) {}
            """),
        // Block comment with Parameters: block
        Example(code:
            """
            /**
             * Adds two numbers.
             * - Parameters:
             *   - lhs: Left operand.
             *   - rhs: Right operand.
             * - Returns: Their sum.
             */
            func add(lhs: Int, rhs: Int) -> Int { lhs + rhs }
            """),
    ]

    static let triggeringExamples = [
        // Documented parameter doesn't exist
        Example(code:
            """
            /// Greets someone.
            /// - Parameter ↓name: The name to greet.
            func greet() {}
            """),
        // One parameter missing from documentation
        Example(code:
            """
            /// Adds two numbers.
            /// - Parameter lhs: Left-hand side.
            ↓func add(lhs: Int, rhs: Int) -> Int { lhs + rhs }
            """),
        // Documented parameter name doesn't match
        Example(code:
            """
            /// Processes a value.
            /// - Parameter ↓val: The value.
            ↓func process(value: Int) {}
            """),
        // Missing one of multiple parameters
        Example(code:
            """
            /// Processes values.
            /// - Parameters:
            ///   - first: The first value.
            ↓func process(first: Int, second: Int) {}
            """),
        // Extra documented parameter that doesn't exist
        Example(code:
            """
            /// Does something.
            /// - Parameters:
            ///   - value: A value.
            ///   - ↓extra: This doesn't exist.
            func doSomething(value: Int) {}
            """),
        // External label used instead of internal name
        Example(code:
            """
            /// Updates the label.
            /// - Parameter ↓with: The new text.
            ↓func updateLabel(with text: String) {}
            """),
        // validate_returns: missing returns doc
        Example(code:
            """
            /// Computes a value.
            ↓func compute() -> Int { 0 }
            """, configuration: ["validate_returns": true]),
        // validate_returns: unexpected returns doc on void function
        Example(code:
            """
            /// Does something.
            /// - ↓Returns: Some value.
            func doSomething() {}
            """, configuration: ["validate_returns": true]),
        // validate_throws: missing throws doc
        Example(code:
            """
            /// Parses the input.
            ↓func parse() throws {}
            """, configuration: ["validate_throws": true]),
        // validate_throws: unexpected throws doc on non-throwing function
        Example(code:
            """
            /// Does something safe.
            /// - ↓Throws: Some error.
            func safe() {}
            """, configuration: ["validate_throws": true]),
        // enforce_parameter_syntax: plural block with 1 param — should use singular
        Example(code:
            """
            /// Does something.
            /// - ↓Parameters:
            ///   - value: The value.
            func single(value: Int) {}
            """, configuration: ["enforce_parameter_syntax": true]),
        // enforce_parameter_syntax: multiple singular lines with 2+ params — should use plural
        Example(code:
            """
            /// Does something.
            /// - Parameter a: First.
            /// - ↓Parameter b: Second.
            func multi(a: Int, b: Int) {}
            """, configuration: ["enforce_parameter_syntax": true]),
    ]
}
