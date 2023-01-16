internal enum OperatorUsageWhitespaceRuleExamples {
    static let nonTriggeringExamples = [
        Example("let foo = 1 + 2\n"),
        Example("let foo = 1 > 2\n"),
        Example("let foo = !false\n"),
        Example("let foo: Int?\n"),
        Example("let foo: Array<String>\n"),
        Example("let model = CustomView<Container<Button>, NSAttributedString>()\n"),
        Example("let foo: [String]\n"),
        Example("let foo = 1 + \n  2\n"),
        Example("let range = 1...3\n"),
        Example("let range = 1 ... 3\n"),
        Example("let range = 1..<3\n"),
        Example("#if swift(>=3.0)\n    foo()\n#endif\n"),
        Example("array.removeAtIndex(-200)\n"),
        Example("let name = \"image-1\"\n"),
        Example("button.setImage(#imageLiteral(resourceName: \"image-1\"), for: .normal)\n"),
        Example("let doubleValue = -9e-11\n"),
        Example("let foo = GenericType<(UIViewController) -> Void>()\n"),
        Example("let foo = Foo<Bar<T>, Baz>()\n"),
        Example("let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)\n"),
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
        internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
            return lhs.filePath == rhs.filePath
                && lhs.originalRemoteString == rhs.originalRemoteString
                && lhs.rootDirectory == rhs.rootDirectory
        }
        """),
        Example("""
        internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
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
        )
    ]

    static let triggeringExamples = [
        Example("let foo = 1↓+2\n"),
        Example("let foo = 1↓   + 2\n"),
        Example("let foo = 1↓   +    2\n"),
        Example("let foo = 1↓ +    2\n"),
        Example("let foo↓=1↓+2\n"),
        Example("let foo↓=1 + 2\n"),
        Example("let foo↓=bar\n"),
        Example("let range = 1↓ ..<  3\n"),
        Example("let foo = bar↓   ?? 0\n"),
        Example("let foo = bar↓ !=  0\n"),
        Example("let foo = bar↓ !==  bar2\n"),
        Example("let v8 = Int8(1)↓  << 6\n"),
        Example("let v8 = 1↓ <<  (6)\n"),
        Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n"),
        Example("let foo↓  = [1]\n"),
        Example("let foo↓  = \"1\"\n"),
        Example("let foo↓ =  \"1\"\n"),
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
        Example("let foo = bar↓ ?   0 : 1")
    ]

    static let corrections = [
        Example("let foo = 1↓+2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo = 1↓   + 2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo = 1↓   +    2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo = 1↓ +    2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo↓=1↓+2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo↓=1 + 2\n"): Example("let foo = 1 + 2\n"),
        Example("let foo↓=bar\n"): Example("let foo = bar\n"),
        Example("let range = 1↓ ..<  3\n"): Example("let range = 1..<3\n"),
        Example("let foo = bar↓   ?? 0\n"): Example("let foo = bar ?? 0\n"),
        Example("let foo = bar↓ !=  0\n"): Example("let foo = bar != 0\n"),
        Example("let foo = bar↓ !==  bar2\n"): Example("let foo = bar !== bar2\n"),
        Example("let v8 = Int8(1)↓  << 6\n"): Example("let v8 = Int8(1) << 6\n"),
        Example("let v8 = 1↓ <<  (6)\n"): Example("let v8 = 1 << (6)\n"),
        Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n"): Example("let v8 = 1 << (6)\n let foo = 1 > 2\n"),
        Example("let foo↓  = \"1\"\n"): Example("let foo = \"1\"\n"),
        Example("let foo↓ =  \"1\"\n"): Example("let foo = \"1\"\n"),
        Example("let foo = bar ? 0↓:1"): Example("let foo = bar ? 0 : 1"),
        Example("let foo = bar↓ ?   0 : 1"): Example("let foo = bar ? 0 : 1")
    ]
}
