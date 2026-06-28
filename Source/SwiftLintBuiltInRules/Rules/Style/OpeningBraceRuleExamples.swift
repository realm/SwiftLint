// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
struct OpeningBraceRuleExamples {
    static let nonTriggeringExamples = #examples([
        "func abc() {\n}",
        "[].map() { $0 }",
        "[].map({ })",
        "if let a = b { }",
        "while a == b { }",
        "guard let a = b else { }",
        "struct Rule {}",
        "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}",
        """
            func f(rect: CGRect) {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }()
            }
            """,
        """
            func f(rect: CGRect) -> () -> Void {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }
            }
            """,
        """
            func f() -> () -> Void {
                {}
            }
            """,
        """
            class Rule:
              NSObject {
              var a: String {
                return ""
              }
            }
            """,
        """
            self.foo(
                (
                    "String parameter",
                    { "Do something here" }
                )
            )
            """,
        ##"let pattern = #/(\{(?<key>\w+)\})/#"##,
        """
            if c {}
            else {}
            """,
        """
            if c /* comment */ {
                return
            }
        """,
    ])

    static let triggeringExamples = [
        Example("func abc()↓{\n}"),
        Example("func abc()\n\t↓{ }"),
        Example("func abc(a: A,\n\tb: B)\n↓{"),
        Example("[].map()↓{ $0 }"),
        Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button(action: {
                  self.showOptions.toggle()
                })↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
        Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button(action: {
                  self.showOptions.toggle()
                })
               ↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
        Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button {
                  self.showOptions.toggle()
                } label:↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
        Example("if let a = b↓{ }"),
        Example("while a == b↓{ }"),
        Example("guard let a = b else↓{ }"),
        Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
        Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
        Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else↓{ }"),
        Example("struct Rule↓{}"),
        Example("struct Rule\n↓{\n}"),
        Example("struct Rule\n\n\t↓{\n}"),
        Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}"),
        Example("switch a↓{}"),
        Example("if\n\tlet a = b,\n\tlet c = d,\n\ta == c\n↓{ }"),
        Example("while\n\tlet a = b,\n\tlet c = d,\n\ta == c\n↓{ }"),
        Example("guard\n\tlet a = b,\n\tlet c = d,\n\ta == c else\n↓{ }"),
        Example("class Rule↓{}\n"),
        Example("actor Rule↓{}\n"),
        Example("enum Rule↓{}\n"),
        Example("protocol Rule↓{}\n"),
        Example("extension Rule↓{}\n"),
        Example("""
            class Rule {
              var a: String↓{
                return ""
              }
            }
            """),
        Example("""
            class Rule {
              var a: String {
                willSet↓{

                }
                didSet  ↓{

                }
              }
            }
            """),
        Example("""
            precedencegroup Group↓{
              assignment: true
            }
            """),
        Example("""
            internal static func getPointer()
              -> UnsafeMutablePointer<_ThreadLocalStorage>
            ↓{
                return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                    to: _ThreadLocalStorage.self)
            }
            """, excludeFromDocumentation: true),
        Example("""
            func run_Array_method1x(_ N: Int) {
              let existentialArray = array!
              for _ in 0 ..< N * 100 {
                for elt in existentialArray {
                  if !elt.doIt()  {
                    fatalError("expected true")
                  }
                }
              }
            }

            func run_Array_method2x(_ N: Int) {

            }
            """, excludeFromDocumentation: true),
        Example("""
            class TestFile {
               func problemFunction() {
                   #if DEBUG
                   #endif
               }

               func openingBraceViolation()
              ↓{
                   print("Brackets")
               }
            }
            """, excludeFromDocumentation: true),
        Example("""
            if
                "test".isEmpty
            ↓{
                // code here
            }
            """),
        Example("""
            func fooFun() {
                let foo: String? = "foo"
                let bar: String? = "bar"

                if
                    let foo = foo,
                    let bar = bar
                ↓{
                    print(foo + bar)
                }
            }
            """),
        Example("""
            if
                let a = ["A", "B"].first,
                let b = ["B"].first
            ↓{
                print(a)
            }
            """),
        Example("""
            if c  ↓{}
            else /* comment */  ↓{}
            """),
    ]

    static let corrections = #examplesDictionary([
        "struct Rule{}": "struct Rule {}",
        "struct Rule\n{\n}": "struct Rule {\n}",
        "struct Rule\n\n\t{\n}": "struct Rule {\n}",
        "struct Parent {\n\tstruct Child\n\t{\n\t\tlet foo: Int\n\t}\n}":
            "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}",
        "[].map(){ $0 }": "[].map() { $0 }",
        "if a == b{ }": "if a == b { }",
        "if\n\tlet a = b,\n\tlet c = d{ }": "if\n\tlet a = b,\n\tlet c = d { }",
        """
            actor MyActor  {

            }
            """: """
                actor MyActor {

                }
                """,
        """
            actor MyActor
            {

            }
            """: """
                actor MyActor {

                }
                """,
        """
            actor MyActor<T>  {

            }
            """: """
                actor MyActor<T> {

                }
                """,
        """
            actor MyActor<T> where T: U  {

            }
            """: """
                actor MyActor<T> where T: U {

                }
                """,
        """
            class Rule  {

            }
            """: """
                class Rule {

                }
                """,
        """
            class Rule
            {

            }
            """: """
                class Rule {

                }
                """,
        """
            class Rule<T>  {

            }
            """: """
                class Rule<T> {

                }
                """,
        """
            class Rule<T>: NSObject  {

            }
            """: """
                class Rule<T>: NSObject {

                }
                """,
        """
            class Rule<T>: NSObject where T: U  {

            }
            """: """
                class Rule<T>: NSObject where T: U {

                }
                """,
        """
            enum Rule
            {

            }
            """: """
                enum Rule {

                }
                """,
        """
            enum Rule: E  {

            }
            """: """
                enum Rule: E {

                }
                """,
        """
            extension Rule
            {

            }
            """: """
                extension Rule {

                }
                """,
        """
            protocol Rule  {

            }
            """: """
                protocol Rule {

                }
                """,
        """
            struct Rule
            {

            }
            """: """
                struct Rule {

                }
                """,
        """
            struct Rule  : A
            {

            }
            """: """
                struct Rule  : A {

                }
                """,
        """
            do {

            } catch
            {

            }
            """: """
                do {

                } catch {

                }
                """,
        """
            do {

            } catch MyError.unknown  {

            }
            """: """
                do {

                } catch MyError.unknown {

                }
                """,
        """
            do {

            } catch let error  {

            }
            """: """
                do {

                } catch let error {

                }
                """,
        """
            defer  {

            }
            """: """
                defer {

                }
                """,
        """
            do  {

            }
            """: """
            do {

            }
            """,
        """
            for a in b
            {

            }
            """: """
            for a in b {

            }
            """,
        """
            for a in b where a == c  {

            }
            """: """
                for a in b where a == c {

                }
                """,
        """
            guard a == b else
            {
              return ""
            }
            """: """
                guard a == b else {
                  return ""
                }
                """,
        "if\n\tlet a = b,\n\tlet c = d{ }\n": "if\n\tlet a = b,\n\tlet c = d { }\n",
        """
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self)
            { // Complex or collection type
                return .visitChildren
            }
            """: """
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                    || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                    || !node.type.is(SimpleTypeIdentifierSyntax.self) { // Complex or collection type
                    return .visitChildren
                }
                """,
        """
            repeat  {

            } while a
            """: """
                repeat {

                } while a
                """,
        """
            while a  {

            }
            """: """
                while a {

                }
                """,
        "class Rule{}": "class Rule {}",
        "actor Rule{}": "actor Rule {}",
        "enum Rule{}": "enum Rule {}",
        "protocol Rule{}": "protocol Rule {}",
        "extension Rule{}": "extension Rule {}",
        """
            class Rule {
              var a: String {
                willSet{

                }
              }
            }
            """: """
                class Rule {
                  var a: String {
                    willSet {

                    }
                  }
                }
                """,
        """
            class Rule {
              var a: String {
                didSet  {

                }
              }
            }
            """: """
                class Rule {
                  var a: String {
                    didSet {

                    }
                  }
                }
                """,
        """
            precedencegroup Group{
              assignment: true
            }
            """: """
                precedencegroup Group {
                  assignment: true
                }
                """,
        """
            if c /* comment */    {
                return
            }
        """: """
                if c /* comment */ {
                    return
                }
            """,
        // https://github.com/realm/SwiftLint/issues/5598
        """
            if c    // A comment
            {
                return
            }
        """: """
                if c { // A comment
                    return
                }
            """,
        // https://github.com/realm/SwiftLint/issues/5751
        """
            if c    // A comment
            { // Another comment
                return
            }
        """: """
                if c { // A comment // Another comment
                    return
                }
            """,
        // https://github.com/realm/SwiftLint/issues/5751
        """
            func foo() {
                if q1, q2
                {
                    do1()
                } else if q3, q4
                {
                    do2()
                }
            }
            """: """
                func foo() {
                    if q1, q2 {
                        do1()
                    } else if q3, q4 {
                        do2()
                    }
                }
                """,
        """
            if
                "test".isEmpty
            // swiftlint:disable:next opening_brace
            {
                // code here
            }
            """: """
                if
                    "test".isEmpty
                // swiftlint:disable:next opening_brace
                {
                    // code here
                }
                """,
    ])
}
