enum UnusedClosureParameterRuleExamples {
    static let nonTriggering = #examples([
        "[1, 2].map { $0 + 1 }",
        "[1, 2].map({ $0 + 1 })",
        "[1, 2].map { number in\n number + 1 \n}",
        "[1, 2].map { _ in\n 3 \n}",
        "[1, 2].something { number, idx in\n return number * idx\n}",
        "let isEmpty = [1, 2].isEmpty()",
        "violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})",
        """
        rlmConfiguration.migrationBlock.map { rlmMigration in
            return { migration, schemaVersion in
                rlmMigration(migration.rlmMigration, schemaVersion)
            }
        }
        """,
        """
        genericsFunc { (a: Type, b) in
            a + b
        }
        """,
        """
        var label: UILabel = { (lbl: UILabel) -> UILabel in
            lbl.backgroundColor = .red
            return lbl
        }(UILabel())
        """,
        """
        hoge(arg: num) { num in
            return num
        }
        """,
        """
        ({ (manager: FileManager) in
          print(manager)
        })(FileManager.default)
        """,
        """
        withPostSideEffect { input in
            if true { print("\\(input)") }
        }
        """,
        """
        viewModel?.profileImage.didSet(weak: self) { (self, profileImage) in
            self.profileImageView.image = profileImage
        }
        """,
        """
        let failure: Failure = { task, error in
            observer.sendFailed(error, task)
        }
        """,
        """
        List($names) { $name in
            Text(name)
        }
        """,
        """
        List($names) { $name in
            TextField($name)
        }
        """,
        #"_ = ["a"].filter { `class` in `class`.hasPrefix("a") }"#,
        "let closure: (Int) -> Void = { `foo` in _ = foo }",
        "let closure: (Int) -> Void = { foo in _ = `foo` }",
    ])

    static let triggering = #examples([
        "[1, 2].map { ↓number in\n return 3 }",
        "[1, 2].map { ↓number in\n return numberWithSuffix }",
        "[1, 2].map { ↓number in\n return 3 // number }",
        "[1, 2].map { ↓number in\n return 3 \"number\" }",
        "[1, 2].something { number, ↓idx in\n return number }",
        "genericsFunc { (↓number: TypeA, idx: TypeB) in return idx }",
        "let c: (Int) -> Void = { foo in _ = .foo }",
        """
        hoge(arg: num) { ↓num in
        }
        """,
        "fooFunc { ↓아 in }",
        "func foo () {\n bar { ↓number in return 3 }",
        """
        viewModel?.profileImage.didSet(weak: self) { (↓self, profileImage) in
            profileImageView.image = profileImage
        }
        """,
        """
        let failure: Failure = { ↓task, error in
            observer.sendFailed(error)
        }
        """,
        """
        List($names) { ↓$name in
            Text("Foo")
        }
        """,
        """
        let class1 = "a"
        _ = ["a"].filter { ↓`class` in `class1`.hasPrefix("a") }
        """,
    ])

    static let corrections = #corrections([
        "[1, 2].map { ↓number in return 3 }":
            "[1, 2].map { _ in return 3 }",
        "[1, 2].map { ↓number in return numberWithSuffix }":
            "[1, 2].map { _ in return numberWithSuffix }",
        "[1, 2].map { ↓number in return 3 // number }":
            "[1, 2].map { _ in return 3 // number }",
        "[1, 2].something { number, ↓idx in return number }":
            "[1, 2].something { number, _ in return number }",
        "genericsFunc(closure: { (↓int: Int) -> Void in // do something })":
            "genericsFunc(closure: { (_: Int) -> Void in // do something })",
        "genericsFunc { (↓a, ↓b: Type) -> Void in }":
            "genericsFunc { (_, _: Type) -> Void in }",
        "genericsFunc { (↓a: Type, ↓b: Type) -> Void in }":
            "genericsFunc { (_: Type, _: Type) -> Void in }",
        "genericsFunc { (↓a: Type, ↓b) -> Void in }":
            "genericsFunc { (_: Type, _) -> Void in }",
        "genericsFunc { (a: Type, ↓b) -> Void in return a }":
            "genericsFunc { (a: Type, _) -> Void in return a }",
        "hoge(arg: num) { ↓num in }":
            "hoge(arg: num) { _ in }",
        """
        func foo () {
          bar { ↓number in
            return 3
          }
        }
        """:
            """
            func foo () {
              bar { _ in
                return 3
              }
            }
            """,
        """
        class C {
        #if true
            func f() {
                [1, 2].map { ↓number in
                    return 3
                }
            }
        #endif
        }
        """:
            """
            class C {
            #if true
                func f() {
                    [1, 2].map { _ in
                        return 3
                    }
                }
            #endif
            }
            """,
        """
        let failure: Failure = { ↓task, error in
            observer.sendFailed(error)
        }
        """:
            """
            let failure: Failure = { _, error in
                observer.sendFailed(error)
            }
            """,
    ])
}
