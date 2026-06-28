internal struct PrivateSubjectRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        #"""
            final class Foobar {
                private let goodSubject = PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                fileprivate let goodSubject: PassthroughSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                fileprivate let goodSubject: CurrentValueSubject<String, Never>
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<String, Never> = .init("toto")
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject = PassthroughSubject<Set<String>, Never>()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Set<String>, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Set<String>, Never> = .init([])
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject =
                    PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject:
                    PassthroughSubject<Bool, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject =
                    CurrentValueSubject<Bool, Never>(true)
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Bool, Never>
                init() {
                    let goodSubject = CurrentValueSubject<Bool, Never>(true)
                    self.goosSubject = goodSubject
                }
            }
            """#,
        """
            func foo() {
                let goodSubject = PassthroughSubject<Bool, Never>(true)
            }
            """,
    ])

    static let triggeringExamples: [Example] = #examples([
        #"""
            final class Foobar {
                let ↓badSubject = PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject: PassthroughSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject: PassthroughSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                let goodSubject: PassthroughSubject<Bool, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: PassthroughSubject<Bool, Never>
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
                private(set) let ↓anotherBadSubject = PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject = PassthroughSubject<Bool, Never>()
                private let goodSubject: PassthroughSubject<Bool, Never>
                private(set) let ↓anotherBadSubject = PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject = CurrentValueSubject<Bool, Never>(true)
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject: CurrentValueSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject: CurrentValueSubject<Bool, Never>
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#,
        #"""
            final class Foobar {
                let goodSubject: CurrentValueSubject<String, Never> = .init("toto")
            }
            """#,
        #"""
            final class Foobar {
                private let goodSubject: CurrentValueSubject<Bool, Never>
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
                private(set) let ↓anotherBadSubject = CurrentValueSubject<Bool, Never>(false)
            }
            """#,
        #"""
            final class Foobar {
                private(set) let ↓badSubject = CurrentValueSubject<Bool, Never>(false)
                private let goodSubject: CurrentValueSubject<Bool, Never>
                private(set) let ↓anotherBadSubject = CurrentValueSubject<Bool, Never>(true)
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject = PassthroughSubject<Set<String>, Never>()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject: PassthroughSubject<Set<String>, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject: CurrentValueSubject<Set<String>, Never> = .init([])
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject =
                    PassthroughSubject<Bool, Never>()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject:
                    PassthroughSubject<Bool, Never> = .init()
            }
            """#,
        #"""
            final class Foobar {
                let ↓badSubject =
                    CurrentValueSubject<Bool, Never>(true)
            }
            """#,
    ])
}
