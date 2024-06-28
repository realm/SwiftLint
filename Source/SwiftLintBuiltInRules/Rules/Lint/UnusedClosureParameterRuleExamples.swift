enum UnusedClosureParameterRuleExamples {
    static let nonTriggering = [
        Example("[1, 2].map { $0 + 1 }"),
        Example("[1, 2].map({ $0 + 1 })"),
        Example("[1, 2].map { number in\n number + 1 \n}"),
        Example("[1, 2].map { _ in\n 3 \n}"),
        Example("[1, 2].something { number, idx in\n return number * idx\n}"),
        Example("let isEmpty = [1, 2].isEmpty()"),
        Example("violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})"),
        Example("""
        rlmConfiguration.migrationBlock.map { rlmMigration in
            return { migration, schemaVersion in
                rlmMigration(migration.rlmMigration, schemaVersion)
            }
        }
        """),
        Example("""
        genericsFunc { (a: Type, b) in
            a + b
        }
        """),
        Example("""
        var label: UILabel = { (lbl: UILabel) -> UILabel in
            lbl.backgroundColor = .red
            return lbl
        }(UILabel())
        """),
        Example("""
        hoge(arg: num) { num in
            return num
        }
        """),
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
        Example(#"_ = ["a"].filter { `class` in `class`.hasPrefix("a") }"#),
        Example("let closure: (Int) -> Void = { `foo` in _ = foo }"),
        Example("let closure: (Int) -> Void = { foo in _ = `foo` }"),
    ]

    static let triggering = [
        Example("[1, 2].map { ↓number in\n return 3 }"),
        Example("[1, 2].map { ↓number in\n return numberWithSuffix }"),
        Example("[1, 2].map { ↓number in\n return 3 // number }"),
        Example("[1, 2].map { ↓number in\n return 3 \"number\" }"),
        Example("[1, 2].something { number, ↓idx in\n return number }"),
        Example("genericsFunc { (↓number: TypeA, idx: TypeB) in return idx }"),
        Example("let c: (Int) -> Void = { foo in _ = .foo }"),
        Example("""
        hoge(arg: num) { ↓num in
        }
        """),
        Example("fooFunc { ↓아 in }"),
        Example("func foo () {\n bar { ↓number in return 3 }"),
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
        """),
    ]

    static let corrections = [
        Example("[1, 2].map { ↓number in return 3 }"):
            Example("[1, 2].map { _ in return 3 }"),
        Example("[1, 2].map { ↓number in return numberWithSuffix }"):
            Example("[1, 2].map { _ in return numberWithSuffix }"),
        Example("[1, 2].map { ↓number in return 3 // number }"):
            Example("[1, 2].map { _ in return 3 // number }"),
        Example("[1, 2].something { number, ↓idx in return number }"):
            Example("[1, 2].something { number, _ in return number }"),
        Example("genericsFunc(closure: { (↓int: Int) -> Void in // do something })"):
            Example("genericsFunc(closure: { (_: Int) -> Void in // do something })"),
        Example("genericsFunc { (↓a, ↓b: Type) -> Void in }"):
            Example("genericsFunc { (_, _: Type) -> Void in }"),
        Example("genericsFunc { (↓a: Type, ↓b: Type) -> Void in }"):
            Example("genericsFunc { (_: Type, _: Type) -> Void in }"),
        Example("genericsFunc { (↓a: Type, ↓b) -> Void in }"):
            Example("genericsFunc { (_: Type, _) -> Void in }"),
        Example("genericsFunc { (a: Type, ↓b) -> Void in return a }"):
            Example("genericsFunc { (a: Type, _) -> Void in return a }"),
        Example("hoge(arg: num) { ↓num in }"):
            Example("hoge(arg: num) { _ in }"),
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
        Example("""
        class C {
        #if true
            func f() {
                [1, 2].map { ↓number in
                    return 3
                }
            }
        #endif
        }
        """):
            Example("""
            class C {
            #if true
                func f() {
                    [1, 2].map { _ in
                        return 3
                    }
                }
            #endif
            }
            """),
        Example("""
        let failure: Failure = { ↓task, error in
            observer.sendFailed(error)
        }
        """):
            Example("""
            let failure: Failure = { _, error in
                observer.sendFailed(error)
            }
            """),
    ]
}
