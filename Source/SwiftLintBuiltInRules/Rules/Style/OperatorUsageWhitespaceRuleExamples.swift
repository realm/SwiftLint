import SwiftLintCore

internal enum OperatorUsageWhitespaceRuleExamples {
    static let nonTriggeringExamples = #examples([
        "let foo = 1 + 2",
        "let foo = 1 > 2",
        "let foo = !false",
        "let foo: Int?",
        "let foo: Array<String>",
        "let model = CustomView<Container<Button>, NSAttributedString>()",
        "let foo: [String]",
        "let foo = 1 + \n  2",
        "let range = 1...3",
        "let range = 1 ... 3",
        "let range = 1..<3",
        "#if swift(>=3.0)\n    foo()\n#endif",
        "array.removeAtIndex(-200)",
        "let name = \"image-1\"",
        "button.setImage(#imageLiteral(resourceName: \"image-1\"), for: .normal)",
        "let doubleValue = -9e-11",
        "let foo = GenericType<(UIViewController) -> Void>()",
        "let foo = Foo<Bar<T>, Baz>()",
        "let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)",
        "\"let foo =  1\"",
        """
        enum Enum {
        case hello   = 1
        case hello2  = 1
        }
        """,
        """
        let something = Something<GenericParameter1,
                                  GenericParameter2>()
        """,
        """
        return path.flatMap { path in
            return compileCommands[path] ??
                compileCommands[path.path(relativeTo: FileManager.default.currentDirectoryPath)]
        }
        """,
        """
        internal static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            return lhs.filePath == rhs.filePath
                && lhs.originalRemoteString == rhs.originalRemoteString
                && lhs.rootDirectory == rhs.rootDirectory
        }
        """,
        """
        internal static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            return lhs.filePath == rhs.filePath &&
                lhs.originalRemoteString == rhs.originalRemoteString &&
                lhs.rootDirectory == rhs.rootDirectory
        }
        """,
        #"""
        private static let pattern =
            "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
            "|" +                       // or
            "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
        """#,
        #"""
        private static let pattern =
            "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
            "|"                       + // or
            "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
        """#,
        "typealias Foo = Bar",
        """
        protocol A {
            associatedtype B = C
        }
        """,
        "tabbedViewController.title = nil",
        #"""
        return deferMaybe(lastTimestamp)
              >>== uploadDeleted
              >>== uploadModified
               >>> effect({ log.debug("Done syncing. Work was done? \(workWasDone)") })
               >>> { workWasDone ? storage.doneUpdatingMetadataAfterUpload() : succeed() }    // A closure
               >>> effect({ log.debug("Done.") })
        """#.excludeFromDocumentation(),
        """
        func success(for item: Item) {
            item.successHandler??()
        }
        """.excludeFromDocumentation(),
        """
        func getAllowedTimeRange(startTime: TimeOfDay) -> TimeOfDayRange {
            let endTime = startTime + 3.hours
            return startTime<--<endTime
        }
        """.configuration(["allowed_no_space_operators": ["<--<"]]).excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
        "let foo = 1↓+2",
        "let foo = 1↓   + 2",
        "let foo = 1↓   +    2",
        "let foo = 1↓ +    2",
        "let foo↓=1↓+2",
        "let foo↓=1 + 2",
        "let foo↓=bar",
        "let range = 1↓ ..<  3",
        "let foo = bar↓   ?? 0",
        "let foo = bar↓ !=  0",
        "let foo = bar↓ !==  bar2",
        "let v8 = Int8(1)↓  << 6",
        "let v8 = 1↓ <<  (6)",
        "let v8 = 1↓ <<  (6)\n let foo = 1 > 2",
        "let foo↓  = [1]",
        "let foo↓  = \"1\"",
        "let foo↓ =  \"1\"",
        """
        enum Enum {
        case one↓  =  1
        case two  = 1
        }
        """,
        """
        enum Enum {
        case one  = 1
        case two↓  =  1
        }
        """,
        """
        enum Enum {
        case one↓   = 1
        case two↓  = 1
        }
        """,
        "typealias Foo↓ =  Bar",
        """
        protocol A {
            associatedtype B↓  = C
        }
        """,
        "tabbedViewController.title↓  = nil",
        "let foo = bar ? 0↓:1",
        "let foo = bar↓ ?   0 : 1",
    ])

    static let corrections = #corrections([
        "let foo = 1↓+2": "let foo = 1 + 2",
        "let foo = 1↓   + 2": "let foo = 1 + 2",
        "let foo = 1↓   +    2": "let foo = 1 + 2",
        "let foo = 1↓ +    2": "let foo = 1 + 2",
        "let foo↓=1↓+2": "let foo = 1 + 2",
        "let foo↓=1 + 2": "let foo = 1 + 2",
        "let foo↓=bar": "let foo = bar",
        "let range = 1↓ ..<  3": "let range = 1..<3",
        "let foo = bar↓   ?? 0": "let foo = bar ?? 0",
        "let foo = bar↓ !=  0": "let foo = bar != 0",
        "let foo = bar↓ !==  bar2": "let foo = bar !== bar2",
        "let v8 = Int8(1)↓  << 6": "let v8 = Int8(1) << 6",
        "let v8 = 1↓ <<  (6)": "let v8 = 1 << (6)",
        "let v8 = 1↓ <<  (6)\n let foo = 1 > 2": "let v8 = 1 << (6)\n let foo = 1 > 2",
        "let foo↓  = \"1\"": "let foo = \"1\"",
        "let foo↓ =  \"1\"": "let foo = \"1\"",
        "let foo = bar ? 0↓:1": "let foo = bar ? 0 : 1",
        "let foo = bar↓ ?   0 : 1": "let foo = bar ? 0 : 1",
    ])
}
