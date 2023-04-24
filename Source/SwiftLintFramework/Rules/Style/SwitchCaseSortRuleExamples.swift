enum SwitchCaseSortRuleExamples {
    // to see the triggering and correction subsequently
    static let examples: (triggering: [Example], nonTriggering: [Example], corrections: [Example: Example]) = {
        var triggering = [Example]()
        var nonTriggering = [Example]()
        triggering.append(
            Example("""
            ↓switch foo {
            case .b:
                break
            case .a:
                break
            case .c:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case .a:
                break
            case .b:
                break
            case .c:
                break
            }
            """)
        )
        triggering.append(
            Example("""
            switch foo {
            ↓case .b, .a, .c:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case .a, .b, .c:
                break
            }
            """)
        )
        triggering.append(
            Example("""
            switch foo {
            case .a:
                break
            ↓case .c, .b:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case .a:
                break
            case .b, .c:
                break
            }
            """)
        )
        triggering.append(
            Example("""
            ↓switch foo {
            case .z:
                break
            ↓case .c, .b:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case .b, .c:
                break
            case .z:
                break
            }
            """)
        )
        triggering.append(
            Example("""
            ↓switch foo {
            case .d:
                break
            case .a:
                break
            default:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case .a:
                break
            case .d:
                break
            default:
                break
            }
            """)
        )
        //    triggering.append(
        //        // this is a compiler error, no need to handle it:
        //        // Additional 'case' blocks cannot appear after the 'default' block of a 'switch'
        //        Example("""
        //        ↓switch foo {
        //        case .d:
        //            break
        //        default:
        //            break
        //        case .a:
        //            break
        //        }
        //        """)
        //    )
        //    nonTriggering.append(
        //        Example("""
        //        switch foo {
        //        case .a:
        //            break
        //        case .d:
        //            break
        //        default:
        //            break
        //        }
        //        """)
        //    )
        triggering.append(
            Example("""
            ↓switch foo {
            case "c":
                break
            case "a":
                break
            case "b":
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case "a":
                break
            case "b":
                break
            case "c":
                break
            }
            """)
        )
        triggering.append(
            Example(#"""
            ↓switch foo {
            case "c \(bar)": // bar is a variable
                break
            case "a":
                break
            case "b":
                break
            }
            """#)
        )
        nonTriggering.append(
            Example(#"""
            switch foo {
            case "a":
                break
            case "b":
                break
            case "c \(bar)": // bar is a variable
                break
            }
            """#)
        )
        triggering.append(
            Example(#"""
            ↓switch foo {
            case "\(bar) c": // bar is a variable
                break
            case "a":
                break
            case "b":
                break
            }
            """#)
        )
        nonTriggering.append(
            Example(#"""
            switch foo {
            case "a":
                break
            case "b":
                break
            case "\(bar) c": // bar is a variable
                break
            }
            """#)
        )
        triggering.append(
            Example("""
            ↓switch foo {
            case 2:
                break
            case 1:
                break
            case 3:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case 1:
                break
            case 2:
                break
            case 3:
                break
            }
            """)
        )
        triggering.append(
            Example("""
            ↓switch foo {
            case 2.2:
                break
            case 1.1:
                break
            case 3.3:
                break
            }
            """)
        )
        nonTriggering.append(
            Example("""
            switch foo {
            case 1.1:
                break
            case 2.2:
                break
            case 3.3:
                break
            }
            """)
        )

        let corrections: [Example: Example] = zip(triggering, nonTriggering).reduce(into: [:]) { result, pair in
            // correction location is always before switch keyword
            let toBeCorrected = pair.0.with(
                code: pair.0.code.replacingOccurrences(of: "↓", with: "")
                    .replacingOccurrences(of: "switch", with: "↓switch")
            )
            result[toBeCorrected] = pair.1
        }

        return (triggering, nonTriggering, corrections)
    }()
}
