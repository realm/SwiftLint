internal struct PrivateSubjectRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example(
            #"""
            final class Foobar {
                private let goodSubject = PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                fileprivate let goodSubject: PassthroughSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                fileprivate let goodSubject: CurrentValueSubject<String, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<String, Never> = .init("toto")
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject = PassthroughSubject<Set<String>, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Set<String>, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Set<String>, Never> = .init([])
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject =
                    PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject:
                    PassthroughSubject<Bool, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject =
                    CurrentValueSubject<Bool, Never>(true)
            }
            """#
        ),
        Example(
            """
            func foo() {
                let goodSubject = PassthroughSubject<Bool, Never>(true)
            }
            """
        )
    ]

    static let triggeringExamples: [Example] = [
        Example(
            #"""
            final class Foobar {
                let ↓badSubject = PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject: PassthroughSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject: PassthroughSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let goodSubject: PassthroughSubject<Bool, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never>
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
                private(set) let ↓anotherBadSubject = PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
                private let goodSubject: PassthroughSubject<Bool, Never>
                private(set) let ↓anotherBadSubject = PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject = CurrentValueSubject<Bool, Never>(true)
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject: CurrentValueSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject: CurrentValueSubject<Bool, Never>
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let goodSubject: CurrentValueSubject<String, Never> = .init("toto")
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Bool, Never>
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
                private(set) let ↓anotherBadSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
                private let goodSubject: CurrentValueSubject<Bool, Never>
                private(set) let ↓anotherBadSubject = CurrentValueSubject<Bool, Never>(true)
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject = PassthroughSubject<Set<String>, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject: PassthroughSubject<Set<String>, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject: CurrentValueSubject<Set<String>, Never> = .init([])
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject =
                    PassthroughSubject<Bool, Never>()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject:
                    PassthroughSubject<Bool, Never> = .init()
            }
            """#
        ),
        Example(
            #"""
            final class Foobar {
                let ↓badSubject =
                    CurrentValueSubject<Bool, Never>(true)
            }
            """#
        )
    ]
}
