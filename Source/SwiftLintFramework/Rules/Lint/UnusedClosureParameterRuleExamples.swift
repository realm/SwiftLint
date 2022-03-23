enum UnusedClosureParameterRuleExamples {
    static let nonTriggering = [
        Example("[1, 2].map { $0 + 1 }\n"),
        Example("[1, 2].map({ $0 + 1 })\n"),
        Example("[1, 2].map { number in\n number + 1 \n}\n"),
        Example("[1, 2].map { _ in\n 3 \n}\n"),
        Example("[1, 2].something { number, idx in\n return number * idx\n}\n"),
        Example("let isEmpty = [1, 2].isEmpty()\n"),
        Example("violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})\n"),
        Example("rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
            "return { migration, schemaVersion in\n" +
            "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
            "}\n" +
        "}"),
        Example("genericsFunc { (a: Type, b) in\n" +
            "a + b\n" +
        "}\n"),
        Example("var label: UILabel = { (lbl: UILabel) -> UILabel in\n" +
        "   lbl.backgroundColor = .red\n" +
        "   return lbl\n" +
        "}(UILabel())\n"),
        Example("hoge(arg: num) { num in\n" +
        "  return num\n" +
        "}\n"),
        Example("""
        ({ (manager: FileManager) in
          print(manager)
        })(FileManager.default)
        """),
        Example("""
        withPostSideEffect { input in
            if true { print("\\(input)") }
        }
        """),
        Example("""
        viewModel?.profileImage.didSet(weak: self) { (self, profileImage) in
            self.profileImageView.image = profileImage
        }
        """),
        Example("""
        let failure: Failure = { task, error in
            observer.sendFailed(error, task)
        }
        """),
        Example("""
        List($names) { $name in
            Text(name)
        }
        """),
        Example("""
        List($names) { $name in
            TextField($name)
        }
        """),
        Example(#"_ = ["a"].filter { `class` in `class`.hasPrefix("a") }"#)
    ]

    static let triggering = [
        Example("[1, 2].map { ↓number in\n return 3\n}\n"),
        Example("[1, 2].map { ↓number in\n return numberWithSuffix\n}\n"),
        Example("[1, 2].map { ↓number in\n return 3 // number\n}\n"),
        Example("[1, 2].map { ↓number in\n return 3 \"number\"\n}\n"),
        Example("[1, 2].something { number, ↓idx in\n return number\n}\n"),
        Example("genericsFunc { (↓number: TypeA, idx: TypeB) in return idx\n}\n"),
        Example("hoge(arg: num) { ↓num in\n" +
        "}\n"),
        Example("fooFunc { ↓아 in\n }"),
        Example("func foo () {\n bar { ↓number in\n return 3\n}\n"),
        Example("""
        viewModel?.profileImage.didSet(weak: self) { (↓self, profileImage) in
            profileImageView.image = profileImage
        }
        """),
        Example("""
        let failure: Failure = { ↓task, error in
            observer.sendFailed(error)
        }
        """),
        Example("""
        List($names) { ↓$name in
            Text("Foo")
        }
        """),
        Example("""
        let class1 = "a"
        _ = ["a"].filter { ↓`class` in `class1`.hasPrefix("a") }
        """)
    ]

    static let corrections = [
        Example("[1, 2].map { ↓number in\n return 3\n}\n"):
            Example("[1, 2].map { _ in\n return 3\n}\n"),
        Example("[1, 2].map { ↓number in\n return numberWithSuffix\n}\n"):
            Example("[1, 2].map { _ in\n return numberWithSuffix\n}\n"),
        Example("[1, 2].map { ↓number in\n return 3 // number\n}\n"):
            Example("[1, 2].map { _ in\n return 3 // number\n}\n"),
        Example("[1, 2].something { number, ↓idx in\n return number\n}\n"):
            Example("[1, 2].something { number, _ in\n return number\n}\n"),
        Example("genericsFunc(closure: { (↓int: Int) -> Void in // do something\n})\n"):
            Example("genericsFunc(closure: { (_: Int) -> Void in // do something\n})\n"),
        Example("genericsFunc { (↓a, ↓b: Type) -> Void in\n}\n"):
            Example("genericsFunc { (_, _: Type) -> Void in\n}\n"),
        Example("genericsFunc { (↓a: Type, ↓b: Type) -> Void in\n}\n"):
            Example("genericsFunc { (_: Type, _: Type) -> Void in\n}\n"),
        Example("genericsFunc { (↓a: Type, ↓b) -> Void in\n}\n"):
            Example("genericsFunc { (_: Type, _) -> Void in\n}\n"),
        Example("genericsFunc { (a: Type, ↓b) -> Void in\nreturn a\n}\n"):
            Example("genericsFunc { (a: Type, _) -> Void in\nreturn a\n}\n"),
        Example("hoge(arg: num) { ↓num in\n}\n"):
            Example("hoge(arg: num) { _ in\n}\n"),
        Example("""
        func foo () {
          bar { ↓number in
            return 3
          }
        }
        """):
            Example("""
            func foo () {
              bar { _ in
                return 3
              }
            }
            """),
        Example("class C {\n #if true\n func f() {\n [1, 2].map { ↓number in\n return 3\n }\n }\n #endif\n}"):
            Example("class C {\n #if true\n func f() {\n [1, 2].map { _ in\n return 3\n }\n }\n #endif\n}"),
        Example("""
        let failure: Failure = { ↓task, error in
            observer.sendFailed(error)
        }
        """):
            Example("""
            let failure: Failure = { _, error in
                observer.sendFailed(error)
            }
            """)
    ]
}
