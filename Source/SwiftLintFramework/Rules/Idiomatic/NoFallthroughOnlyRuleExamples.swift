internal struct NoFallthroughOnlyRuleExamples {
    static let nonTriggeringExamples: [String] = {
        let commonExamples = [
            """
            switch myvar {
            case 1:
                var a = 1
                fallthrough
            case 2:
                var a = 2
            }
            """,
            """
            switch myvar {
            case "a":
                var one = 1
                var two = 2
                fallthrough
            case "b": /* comment */
                var three = 3
            }
            """,
            """
            switch myvar {
            case 1:
                let one = 1
            case 2:
                // comment
                var two = 2
            }
            """,
            """
            switch myvar {
            case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
                var three = 3
                fallthrough
            default:
                var three = 4
            }
            """,
            """
            switch myvar {
            case .alpha:
                var one = 1
            case .beta:
                var three = 3
                fallthrough
            default:
                var four = 4
            }
            """,
            """
            let aPoint = (1, -1)
            switch aPoint {
            case let (x, y) where x == y:
                let A = "A"
            case let (x, y) where x == -y:
                let B = "B"
                fallthrough
            default:
                let C = "C"
            }
            """,
            """
            switch myvar {
            case MyFun(with: { $1 }):
                let one = 1
                fallthrough
            case "abc":
                let two = 2
            }
            """
        ]

        guard SwiftVersion.current >= .five else {
            return commonExamples
        }

        return commonExamples + [
            """
            switch enumInstance {
            case .caseA:
                print("it's a")
            case .caseB:
                fallthrough
            @unknown default:
                print("it's not a")
            }
            """
        ]
    }()

    static let triggeringExamples = [
        """
        switch myvar {
        case 1:
            ↓fallthrough
        case 2:
            var a = 1
        }
        """,
        """
        switch myvar {
        case 1:
            var a = 2
        case 2:
            ↓fallthrough
        case 3:
            var a = 3
        }
        """,
        """
        switch myvar {
        case 1: // comment
            ↓fallthrough
        }
        """,
        """
        switch myvar {
        case 1: /* multi
            line
            comment */
            ↓fallthrough
        case 2:
            var a = 2
        }
        """,
        """
        switch myvar {
        case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
            ↓fallthrough
        default:
            var three = 4
        }
        """,
        """
        switch myvar {
        case .alpha:
            var one = 1
        case .beta:
            ↓fallthrough
        case .gamma:
            var three = 3
        default:
            var four = 4
        }
        """,
        """
        let aPoint = (1, -1)
        switch aPoint {
        case let (x, y) where x == y:
            let A = "A"
        case let (x, y) where x == -y:
            ↓fallthrough
        default:
            let B = "B"
        }
        """,
        """
        switch myvar {
        case MyFun(with: { $1 }):
            ↓fallthrough
        case "abc":
            let two = 2
        }
        """
    ]
}
