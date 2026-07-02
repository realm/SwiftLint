import SwiftLintCore

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

    static let triggeringExamples = #examples([
        // Global actor on public declarations
        "@MainActor public ↓struct S {}",
        "@MainActor public ↓class C {}",
        "@MainActor public ↓enum E { case a }",
        "@MainActor public ↓protocol GlobalActor {}",
        "@MainActor public ↓func globalActor()",

        // Initializers with global actors
        """
            class C {
                @MainActor public ↓init() {}
            }
            """,
        "@MainActor public ↓init<T>()",

        // Subscripts with global actors and sendable generics
        """
            struct S {
                @MainActor public ↓subscript(index: Int) -> String { get }
            }
            """,
        "public ↓subscript<T>(index: T) -> Int where T: ExpressibleByIntegerLiteral & Sendable { get }",

        // Function parameters with concurrency attributes
        "public ↓func sendableClosure(_ block: @Sendable () -> Void)",
        "public ↓func globalActorClosure(_ block: @MainActor () -> Void)",
        "public struct S { public ↓func sendableClosure(_ block: @Sendable () -> Void) }",
        "public ↓init(_ block: @Sendable () -> Void)",
        "public ↓init(param: @MainActor () -> Void)",
        """
            public ↓func tupleParameter(
                _ handlers: (@Sendable () -> Void, @MainActor () -> Void)
            )
            """,
        """
            public ↓func tupleWithSending(
                _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
            )
            """,

        // Generic where clauses with Sendable
        "public ↓func generic<T>() where T: Sendable {}",
        "public ↓struct S<T> where T: Sendable {}",
        "public ↓class C<T> where T: Sendable {}",
        "public ↓enum E<T> where T: Sendable { case a }",
        "public ↓init<T>() where T: Sendable {}",

        // Return types with concurrency attributes
        "public ↓func returnsSendableClosure() -> @Sendable () -> Void",
        "public ↓func returnsActorClosure() -> @MainActor () -> Void",
        "public ↓func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void)",

        // Custom global actors with configuration
        "@MyActor public ↓struct S {}".configuration(["global_actors": ["MyActor"]]),
        "public ↓func globalActorClosure(_ block: @MyActor () -> Void)".configuration(["global_actors": ["MyActor"]]),
        "@MyActor public ↓func customGlobalActor()".configuration(["global_actors": ["MyActor"]]),
        "@MyActor public ↓init()".configuration(["global_actors": ["MyActor"]]),
    ])

    static let corrections = #corrections([
        // Global actor on declarations
        """
            @MainActor
            public enum E { case a }
            """:
            """
                @preconcurrency
                @MainActor
                public enum E { case a }
                """,

        "@MainActor public struct S {}":
            """
                @preconcurrency
                @MainActor public struct S {}
                """,

        "@MainActor public class C {}":
            """
                @preconcurrency
                @MainActor public class C {}
                """,

        "@MainActor public protocol P {}":
            """
                @preconcurrency
                @MainActor public protocol P {}
                """,

        "@MainActor public func globalActor() {}":
            """
                @preconcurrency
                @MainActor public func globalActor() {}
                """,

        // Initializers with global actors
        """
            class C {
                @MainActor public init() {}
            }
            """:
            """
                class C {
                    @preconcurrency
                    @MainActor public init() {}
                }
                """,

        // Subscripts with global actors
        """
            struct S {
                @MainActor public subscript(index: Int) -> String { get }
            }
            """:
            """
                struct S {
                    @preconcurrency
                    @MainActor public subscript(index: Int) -> String { get }
                }
                """,

        // Functions with Sendable parameters
        "public func sendableClosure(_ block: @Sendable () -> Void) {}":
            """
                @preconcurrency
                public func sendableClosure(_ block: @Sendable () -> Void) {}
                """,

        "public func globalActorClosure(_ block: @MainActor () -> Void) {}":
            """
                @preconcurrency
                public func globalActorClosure(_ block: @MainActor () -> Void) {}
                """,

        "public func tupleParameter(_ handlers: (@Sendable () -> Void, @MainActor () -> Void)) {}":
            """
                @preconcurrency
                public func tupleParameter(_ handlers: (@Sendable () -> Void, @MainActor () -> Void)) {}
                """,

        """
            public func tupleWithSending(
                _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
            ) {}
            """:
            """
                @preconcurrency
                public func tupleWithSending(
                    _ handlers: ((_ value: sending MyClass) -> Void, @MainActor () -> Void)
                ) {}
                """,

        // Initializers with Sendable parameters
        "public init(_ block: @Sendable () -> Void) {}":
            """
                @preconcurrency
                public init(_ block: @Sendable () -> Void) {}
                """,

        // Generic where clauses with Sendable
        "public func generic<T>() where T: Sendable {}":
            """
                @preconcurrency
                public func generic<T>() where T: Sendable {}
                """,

        "public struct S<T> where T: Sendable {}":
            """
                @preconcurrency
                public struct S<T> where T: Sendable {}
                """,

        "public subscript<T>(index: T) -> Int where T: Sendable { get }":
            """
                @preconcurrency
                public subscript<T>(index: T) -> Int where T: Sendable { get }
                """,

        "public func returnsSendableClosure() -> @Sendable () -> Void {}":
            """
                @preconcurrency
                public func returnsSendableClosure() -> @Sendable () -> Void {}
                """,

        "public func returnsActorClosure() -> @MainActor () -> Void {}":
            """
                @preconcurrency
                public func returnsActorClosure() -> @MainActor () -> Void {}
                """,

        "public func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void) {}":
            """
                @preconcurrency
                public func returnsClosureTuple() -> (@Sendable () -> Void, @MainActor () -> Void) {}
                """,

        // Custom global actors with configuration
        "@MyActor public struct S {}".configuration(["global_actors": ["MyActor"]]):
            """
                @preconcurrency
                @MyActor public struct S {}
                """,

        "public func globalActorClosure(_ block: @MyActor () -> Void) {}".configuration(["global_actors": ["MyActor"]]):
            """
                @preconcurrency
                public func globalActorClosure(_ block: @MyActor () -> Void) {}
                """,
    ])
}
