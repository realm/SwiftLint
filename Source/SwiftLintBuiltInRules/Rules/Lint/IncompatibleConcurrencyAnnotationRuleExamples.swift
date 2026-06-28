// swiftlint:disable:next type_name
struct IncompatibleConcurrencyAnnotationRuleExamples {
    static let nonTriggeringExamples = #examples([
        // Sendable conformance is fine
        "public struct S: Sendable {}",
        "public class C: Sendable {}",
        "public actor A {}",

        // Non-public declarations are fine
        "private @MainActor struct S { }",
        "@MainActor struct S { }",
        "internal @MainActor func globalActor()",
        "private @MainActor init() {}",
        "internal subscript(index: Int) -> String where String: Sendable { get }",

        // @preconcurrency makes it compatible
        "@preconcurrency @MainActor public struct S {}",
        "@preconcurrency @MainActor public class C {}",
        "@preconcurrency @MainActor public enum E { case a }",
        "@preconcurrency @MainActor public protocol P {}",
        "@preconcurrency @MainActor public func globalActor()",
        "@preconcurrency public func sendableClosure(_ block: @Sendable () -> Void)",
        "@preconcurrency public func globalActorClosure(_ block: @MainActor () -> Void)",
        "@preconcurrency public init(_ block: @Sendable () -> Void)",
        "@preconcurrency public subscript(index: Int) -> String where String: Sendable { get }",
        "@preconcurrency public func sendableReturningClosure() -> @Sendable () -> Void",
        "@preconcurrency public func globalActorReturningClosure() -> @MainActor () -> Void",
        "@preconcurrency public func sendingParameter(_ value: sending MyClass)",
        """
            @preconcurrency public func tupleParameterClosures(
                _ handlers: (@Sendable () -> Void, @MainActor () -> Void)
            )
            """,
        """
            @preconcurrency public func tupleReturningClosures() -> (
                @Sendable () -> Void,
                @MainActor () -> Void
            )
            """,
        """
            @preconcurrency public func closureWithSendingArgument(
                _ handler: (_ value: sending MyClass) -> Void
            )
            """,

        // Non-concurrency related cases
        "public func nonSendableClosure(_ block: () -> Void)",
        "public func generic<T>() where T: Equatable",
        "public func generic<T: Hashable>()",
        "public init<T: Hashable>()",

        // Custom global actors without configuration
        "public @MyActor enum E { case a }",
        "public func customActor(_ block: @MyActor () -> Void)",
    ])

    static let triggeringExamples = [
        // Global actor on public declarations
        Example("@MainActor public ↓struct S {}"),
        Example("@MainActor public ↓class C {}"),
        Example("@MainActor public ↓enum E { case a }"),
        Example("@MainActor public ↓protocol GlobalActor {}"),
        Example("@MainActor public ↓func globalActor()"),

        // Initializers with global actors
        Example("""
            class C {
                @MainActor public ↓init() {}
            }
            """),
        Example("@MainActor public ↓init<T>()"),

        // Subscripts with global actors and sendable generics
        Example("""
            struct S {
                @MainActor public ↓subscript(index: Int) -> String { get }
            }
            """),
        Example("public ↓subscript<T>(index: T) -> Int where T: ExpressibleByIntegerLiteral & Sendable { get }"),

        // Function parameters with concurrency attributes
        Example("public ↓func sendableClosure(_ block: @Sendable () -> Void)"),
        Example("public ↓func globalActorClosure(_ block: @MainActor () -> Void)"),
        Example("public struct S { public ↓func sendableClosure(_ block: @Sendable () -> Void) }"),
        Example("public ↓init(_ block: @Sendable () -> Void)"),
        Example("public ↓init(param: @MainActor () -> Void)"),
        Example("""
            public ↓func tupleParameter(
                _ handlers: (@Sendable () -> Void, @MainActor () -> Void)
            )
            """),
        Example("""
            public ↓func tupleWithSending(
                _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
            )
            """),

        // Generic where clauses with Sendable
        Example("public ↓func generic<T>() where T: Sendable {}"),
        Example("public ↓struct S<T> where T: Sendable {}"),
        Example("public ↓class C<T> where T: Sendable {}"),
        Example("public ↓enum E<T> where T: Sendable { case a }"),
        Example("public ↓init<T>() where T: Sendable {}"),

        // Return types with concurrency attributes
        Example("public ↓func returnsSendableClosure() -> @Sendable () -> Void"),
        Example("public ↓func returnsActorClosure() -> @MainActor () -> Void"),
        Example("public ↓func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void)"),

        // Custom global actors with configuration
        Example(
            "@MyActor public ↓struct S {}",
            configuration: ["global_actors": ["MyActor"]]
        ),
        Example(
            "public ↓func globalActorClosure(_ block: @MyActor () -> Void)",
            configuration: ["global_actors": ["MyActor"]]
        ),
        Example(
            "@MyActor public ↓func customGlobalActor()",
            configuration: ["global_actors": ["MyActor"]]
        ),
        Example(
            "@MyActor public ↓init()",
            configuration: ["global_actors": ["MyActor"]]
        ),
    ]

    static let corrections = [
        // Global actor on declarations
        Example("""
            @MainActor
            public enum E { case a }
            """):
            Example("""
                @preconcurrency
                @MainActor
                public enum E { case a }
                """),

        Example("@MainActor public struct S {}"):
            Example("""
                @preconcurrency
                @MainActor public struct S {}
                """),

        Example("@MainActor public class C {}"):
            Example("""
                @preconcurrency
                @MainActor public class C {}
                """),

        Example("@MainActor public protocol P {}"):
            Example("""
                @preconcurrency
                @MainActor public protocol P {}
                """),

        Example("@MainActor public func globalActor() {}"):
            Example("""
                @preconcurrency
                @MainActor public func globalActor() {}
                """),

        // Initializers with global actors
        Example("""
            class C {
                @MainActor public init() {}
            }
            """):
            Example("""
                class C {
                    @preconcurrency
                    @MainActor public init() {}
                }
                """),

        // Subscripts with global actors
        Example("""
            struct S {
                @MainActor public subscript(index: Int) -> String { get }
            }
            """):
            Example("""
                struct S {
                    @preconcurrency
                    @MainActor public subscript(index: Int) -> String { get }
                }
                """),

        // Functions with Sendable parameters
        Example("public func sendableClosure(_ block: @Sendable () -> Void) {}"):
            Example("""
                @preconcurrency
                public func sendableClosure(_ block: @Sendable () -> Void) {}
                """),

        Example("public func globalActorClosure(_ block: @MainActor () -> Void) {}"):
            Example("""
                @preconcurrency
                public func globalActorClosure(_ block: @MainActor () -> Void) {}
                """),

        Example("public func tupleParameter(_ handlers: (@Sendable () -> Void, @MainActor () -> Void)) {}"):
            Example("""
                @preconcurrency
                public func tupleParameter(_ handlers: (@Sendable () -> Void, @MainActor () -> Void)) {}
                """),

        Example("""
            public func tupleWithSending(
                _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
            ) {}
            """):
            Example("""
                @preconcurrency
                public func tupleWithSending(
                    _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
                ) {}
                """),

        // Initializers with Sendable parameters
        Example("public init(_ block: @Sendable () -> Void) {}"):
            Example("""
                @preconcurrency
                public init(_ block: @Sendable () -> Void) {}
                """),

        // Generic where clauses with Sendable
        Example("public func generic<T>() where T: Sendable {}"):
            Example("""
                @preconcurrency
                public func generic<T>() where T: Sendable {}
                """),

        Example("public struct S<T> where T: Sendable {}"):
            Example("""
                @preconcurrency
                public struct S<T> where T: Sendable {}
                """),

        Example("public subscript<T>(index: T) -> Int where T: Sendable { get }"):
            Example("""
                @preconcurrency
                public subscript<T>(index: T) -> Int where T: Sendable { get }
                """),

        Example("public func returnsSendableClosure() -> @Sendable () -> Void {}"):
            Example("""
                @preconcurrency
                public func returnsSendableClosure() -> @Sendable () -> Void {}
                """),

        Example("public func returnsActorClosure() -> @MainActor () -> Void {}"):
            Example("""
                @preconcurrency
                public func returnsActorClosure() -> @MainActor () -> Void {}
                """),

        Example("public func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void) {}"):
            Example("""
                @preconcurrency
                public func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void) {}
                """),

        // Custom global actors with configuration
        Example(
            "@MyActor public struct S {}",
            configuration: ["global_actors": ["MyActor"]]):
            Example("""
                @preconcurrency
                @MyActor public struct S {}
                """),

        Example(
            "public func globalActorClosure(_ block: @MyActor () -> Void) {}",
            configuration: ["global_actors": ["MyActor"]]):
            Example("""
                @preconcurrency
                public func globalActorClosure(_ block: @MyActor () -> Void) {}
                """),
    ]
}
