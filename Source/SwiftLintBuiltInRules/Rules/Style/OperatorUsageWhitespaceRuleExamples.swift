internal enum OperatorUsageWhitespaceRuleExamples {
    static let nonTriggeringExamples = [
        Example("let foo = 1 + 2"),
        Example("let foo = 1 > 2"),
        Example("let foo = !false"),
        Example("let foo: Int?"),
        Example("let foo: Array<String>"),
        Example("let model = CustomView<Container<Button>, NSAttributedString>()"),
        Example("let foo: [String]"),
        Example("let foo = 1 + \n  2"),
        Example("let range = 1...3"),
        Example("let range = 1 ... 3"),
        Example("let range = 1..<3"),
        Example("#if swift(>=3.0)\n    foo()\n#endif"),
        Example("array.removeAtIndex(-200)"),
        Example("let name = \"image-1\""),
        Example("button.setImage(#imageLiteral(resourceName: \"image-1\"), for: .normal)"),
        Example("let doubleValue = -9e-11"),
        Example("let foo = GenericType<(UIViewController) -> Void>()"),
        Example("let foo = Foo<Bar<T>, Baz>()"),
        Example("let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)"),
        Example("\"let foo =  1\""),
        Example("""
        enum Enum {
        case hello   = 1
        case hello2  = 1
        }
        """),
        Example("""
        let something = Something<GenericParameter1,
                                  GenericParameter2>()
        """ ),
        Example("""
        return path.flatMap { path in
            return compileCommands[path] ??
                compileCommands[path.path(relativeTo: FileManager.default.currentDirectoryPath)]
        }
        """),
        Example("""
        internal static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            return lhs.filePath == rhs.filePath
                && lhs.originalRemoteString == rhs.originalRemoteString
                && lhs.rootDirectory == rhs.rootDirectory
        }
        """),
        Example("""
        internal static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            return lhs.filePath == rhs.filePath &&
                lhs.originalRemoteString == rhs.originalRemoteString &&
                lhs.rootDirectory == rhs.rootDirectory
        }
        """),
        Example(#"""
        private static let pattern =
            "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
            "|" +                       // or
            "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
        """#),
        Example(#"""
        private static let pattern =
            "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
            "|"                       + // or
            "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
        """#),
        Example("typealias Foo = Bar"),
        Example("""
        protocol A {
            associatedtype B = C
        }
        """),
        Example("tabbedViewController.title = nil"),
        Example(#"""
        return deferMaybe(lastTimestamp)
              >>== uploadDeleted
              >>== uploadModified
               >>> effect({ log.debug("Done syncing. Work was done? \(workWasDone)") })
               >>> { workWasDone ? storage.doneUpdatingMetadataAfterUpload() : succeed() }    // A closure
               >>> effect({ log.debug("Done.") })
        """#, excludeFromDocumentation: true),
        Example("""
        func success(for item: Item) {
            item.successHandler??()
        }
        """, excludeFromDocumentation: true),
        Example("""
        func getAllowedTimeRange(startTime: TimeOfDay) -> TimeOfDayRange {
            let endTime = startTime + 3.hours
            return startTime<--<endTime
        }
        """,
        configuration: ["allowed_no_space_operators": ["<--<"]],
        excludeFromDocumentation: true
        ),
    ]

    static let triggeringExamples = [
        Example("let foo = 1↓+2"),
        Example("let foo = 1↓   + 2"),
        Example("let foo = 1↓   +    2"),
        Example("let foo = 1↓ +    2"),
        Example("let foo↓=1↓+2"),
        Example("let foo↓=1 + 2"),
        Example("let foo↓=bar"),
        Example("let range = 1↓ ..<  3"),
        Example("let foo = bar↓   ?? 0"),
        Example("let foo = bar↓ !=  0"),
        Example("let foo = bar↓ !==  bar2"),
        Example("let v8 = Int8(1)↓  << 6"),
        Example("let v8 = 1↓ <<  (6)"),
        Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2"),
        Example("let foo↓  = [1]"),
        Example("let foo↓  = \"1\""),
        Example("let foo↓ =  \"1\""),
        Example("""
        enum Enum {
        case one↓  =  1
        case two  = 1
        }
        """),
        Example("""
        enum Enum {
        case one  = 1
        case two↓  =  1
        }
        """),
        Example("""
        enum Enum {
        case one↓   = 1
        case two↓  = 1
        }
        """),
        Example("typealias Foo↓ =  Bar"),
        Example("""
        protocol A {
            associatedtype B↓  = C
        }
        """),
        Example("tabbedViewController.title↓  = nil"),
        Example("let foo = bar ? 0↓:1"),
        Example("let foo = bar↓ ?   0 : 1"),
    ]

    static let corrections = [
        Example("let foo = 1↓+2"): Example("let foo = 1 + 2"),
        Example("let foo = 1↓   + 2"): Example("let foo = 1 + 2"),
        Example("let foo = 1↓   +    2"): Example("let foo = 1 + 2"),
        Example("let foo = 1↓ +    2"): Example("let foo = 1 + 2"),
        Example("let foo↓=1↓+2"): Example("let foo = 1 + 2"),
        Example("let foo↓=1 + 2"): Example("let foo = 1 + 2"),
        Example("let foo↓=bar"): Example("let foo = bar"),
        Example("let range = 1↓ ..<  3"): Example("let range = 1..<3"),
        Example("let foo = bar↓   ?? 0"): Example("let foo = bar ?? 0"),
        Example("let foo = bar↓ !=  0"): Example("let foo = bar != 0"),
        Example("let foo = bar↓ !==  bar2"): Example("let foo = bar !== bar2"),
        Example("let v8 = Int8(1)↓  << 6"): Example("let v8 = Int8(1) << 6"),
        Example("let v8 = 1↓ <<  (6)"): Example("let v8 = 1 << (6)"),
        Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2"): Example("let v8 = 1 << (6)\n let foo = 1 > 2"),
        Example("let foo↓  = \"1\""): Example("let foo = \"1\""),
        Example("let foo↓ =  \"1\""): Example("let foo = \"1\""),
        Example("let foo = bar ? 0↓:1"): Example("let foo = bar ? 0 : 1"),
        Example("let foo = bar↓ ?   0 : 1"): Example("let foo = bar ? 0 : 1"),
    ]
}
