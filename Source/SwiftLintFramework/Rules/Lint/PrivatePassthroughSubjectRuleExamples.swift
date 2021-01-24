internal struct PrivatePassthroughSubjectRuleExamples {
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
                private let goodSubject: PassthroughSubject<Bool, Never> = .ini()
            }
            """#
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
        )
        ,
        Example(
            #"""
            final class Foobar {
                let goodSubject: PassthroughSubject<Bool, Never> = .ini()
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
        )
    ]
}
