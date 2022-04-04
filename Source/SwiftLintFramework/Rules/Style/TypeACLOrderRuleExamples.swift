// swiftlint:disable:next type_body_length
internal struct TypeACLOrderRuleExamples {
    static var nonTriggeringExamples: [Example] {
        return [
            Example("""
            class Paddys {
                open let location = "Philedelphia"
                public let owners = ["Mac", "Dennis", "Charlie"]
                static var numCatsInWall = 2
                fileprivate let doorLabel = "Pirate"
                private let employees = ["Dee"]

                open func charlieWork() { }
                internal func drink() { }
                private func makeMoney() { }
            }
            """),
            Example("""
            class Paddys {
                open func charlieWork() { }
                open let location = "Philedelphia"

                public let owners = ["Mac", "Dennis", "Charlie"]

                static var numCatsInWall = 2
                internal func drink() { }

                fileprivate let doorLabel = "Pirate"

                private let employees = ["Dee"]
                private func makeMoney() { }
            }
            """),
            Example("""
            class PaddysViewController: UIViewController {
                open let location = "Philedelphia"

                func viewDidLoad() { }

                open func charlieWork() { }
            }
            """),
            Example("""
            // Ignore ACL ordering outside of types
            fileprivate let doorLabel = "Pirate"
            public let employees = ["Dee"]

            private func makeMoney() { }
            open func charlieWork() { }

            class Waitress {
                private let location = "Coffee Shop"
            }
            """),
            Example("""
            class Play {
                let name = "The Nightman Cometh"

                open func sing() { }

                private let director = "Charlie"

                public enum Role {
                    case dayman
                    case nightman
                    case princess
                    case troll
                }

                private func getRole() -> Role { }

                private enum Constants {
                    static let funny = true
                }
            }
            """)
        ]
    }

    static var triggeringExamples: [Example] {
        return [
            Example("""
            class Waitress {
                private let location = "Coffee Shop"
                ↓var name: String { fatalError() }
            }
            """),
            Example("""
            class Paddys {
                public let owners = ["Mac", "Dennis", "Charlie"]

                open func charlieWork() { }
                open ↓let location = "Philedelphia"
            }
            """),
            Example("""
            class Paddys {
                open func charlieWork() { }
                open let location = "Philedelphia"

                public let owners = ["Mac", "Dennis", "Charlie"]

                private func makeMoney() { }

                static var numCatsInWall = 2
                ↓func drink() { }
            }
            """),
            Example("""
            class Play {
                let name = "The Nightman Cometh"

                open func sing() { }

                private let director = "Charlie"

                private enum Constants {
                    static let funny = true
                }

                private func getRole() -> Role { .dayman }

                public ↓enum Role {
                    case dayman
                    case nightman
                    case princess
                    case troll
                }
            }
            """),
            Example("""
            protocol Paddys {
                associatedtype Workers

                private typealias ManSpider = Frank
                public ↓typealias SpiderMan = Frank
            }
            """),
            Example("""
            class Paddys {
                private enum Constants {
                    static let funny = true
                }

                open func charlieWork() { }
                open let location = "Philedelphia"

                public ↓enum Role {
                    case dayman
                    case nightman
                    case princess
                    case troll
                }
            }
            """),
            Example("""
            public let employees = ["Dee"]
            fileprivate let doorLabel = "Pirate"

            class Waitress {
                private let location = "Coffee Shop"
            }

            class Paddys {
                internal func drink() { }
                open ↓func charlieWork() { }
            }
            """),
            Example("""
            class Paddys {
                fileprivate let doorLabel = "Pirate"
                public ↓let owners = ["Mac", "Dennis", "Charlie"]
                open ↓let location = "Philedelphia"
                private let employees = ["Dee"]

                private func makeMoney() { }
                internal ↓func drink() { }
                open ↓func charlieWork() { }
            }
            """),
            Example("""
            protocol Paddys {
                public let owners = ["Mac", "Dennis", "Charlie"]

                private func makeMoney() { }

                init(employees: [String]) { }
                open ↓init() { }
            }
            """),
            Example("""
            protocol Paddys {
                subscript(name: String) -> Double {
                    get { }
                    set { }
                }

                public ↓subscript(id: UUID) -> Double {
                    get { }
                    set { }
                }
            }
            """),
            Example("""
            class PaddysViewController: UIViewController {
                private let employees = ["Dee"]
                @IBInspectable var color: UIColor? = .green
                @IBInspectable open ↓var cornerRadius: CGFloat = 0


                public func viewDidLoad() { }
            }
            """),
            Example("""
            class PaddysViewController: UIViewController {
                @IBInspectable var color: UIColor? = .green

                @IBOutlet fileprivate var sign: UIView!
                @IBOutlet internal ↓var door: UIView!

                public func viewDidLoad() { }
            }
            """),
            Example("""
            class PaddysViewController: UIViewController {
                @IBInspectable var color: UIColor? = .green
                @IBOutlet internal var door: UIView!

                func viewDidLoad() { }
                open func charlieWork() { }

                @IBAction private func open(sender: UIButton) { }
                @IBAction public ↓func close(sender: UIButton) { }

                private func makeMoney() { }
            }
            """),
            Example("""
            class PaddysViewController: UIViewController {
                @IBInspectable var color: UIColor? = .green
                @IBOutlet internal var door: UIView!

                class Paddys {
                    fileprivate let doorLabel = "Pirate"
                    public ↓let owners = ["Mac", "Dennis", "Charlie"]
                    open ↓let location = "Philedelphia"

                    private enum Constants {
                        static let funny = true
                    }

                    ↓class Play {
                        let name = "The Nightman Cometh"

                        open func sing() { }

                        struct Waitress {
                            private let location = "Coffee Shop"
                            ↓var name: String { fatalError() }
                        }
                    }
                }
            }
            """)
        ]
    }
}
