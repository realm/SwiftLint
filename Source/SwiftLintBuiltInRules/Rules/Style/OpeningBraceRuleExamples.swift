// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
struct OpeningBraceRuleExamples {
    static let nonTriggeringExamples = [
        Example("func abc() {\n}"),
        Example("[].map() { $0 }"),
        Example("[].map({ })"),
        Example("if let a = b { }"),
        Example("while a == b { }"),
        Example("guard let a = b else { }"),
        Example("struct Rule {}"),
        Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}"),
        Example("""
            func f(rect: CGRect) {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }()
            }
            """),
        Example("""
            func f(rect: CGRect) -> () -> Void {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }
            }
            """),
        Example("""
            func f() -> () -> Void {
                {}
            }
            """),
        Example("""
            class Rule:
              NSObject {
              var a: String {
                return ""
              }
            }
            """),
        Example("""
            self.foo(
                (
                    "String parameter",
                    { "Do something here" }
                )
            )
            """),
        Example(##"let pattern = #/(\{(?<key>\w+)\})/#"##),
        Example("""
            if c {}
            else {}
            """),
        Example("""
            if c /* comment */ {
                return
            }
        """),
    ]

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

    static let corrections = [
        Example("struct Rule{}"): Example("struct Rule {}"),
        Example("struct Rule\n{\n}"): Example("struct Rule {\n}"),
        Example("struct Rule\n\n\t{\n}"): Example("struct Rule {\n}"),
        Example("struct Parent {\n\tstruct Child\n\t{\n\t\tlet foo: Int\n\t}\n}"):
            Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}"),
        Example("[].map(){ $0 }"): Example("[].map() { $0 }"),
        Example("if a == b{ }"): Example("if a == b { }"),
        Example("if\n\tlet a = b,\n\tlet c = d{ }"): Example("if\n\tlet a = b,\n\tlet c = d { }"),
        Example("""
            actor MyActor  {

            }
            """): Example("""
                actor MyActor {

                }
                """),
        Example("""
            actor MyActor
            {

            }
            """): Example("""
                actor MyActor {

                }
                """),
        Example("""
            actor MyActor<T>  {

            }
            """): Example("""
                actor MyActor<T> {

                }
                """),
        Example("""
            actor MyActor<T> where T: U  {

            }
            """): Example("""
                actor MyActor<T> where T: U {

                }
                """),
        Example("""
            class Rule  {

            }
            """): Example("""
                class Rule {

                }
                """),
        Example("""
            class Rule
            {

            }
            """): Example("""
                class Rule {

                }
                """),
        Example("""
            class Rule<T>  {

            }
            """): Example("""
                class Rule<T> {

                }
                """),
        Example("""
            class Rule<T>: NSObject  {

            }
            """): Example("""
                class Rule<T>: NSObject {

                }
                """),
        Example("""
            class Rule<T>: NSObject where T: U  {

            }
            """): Example("""
                class Rule<T>: NSObject where T: U {

                }
                """),
        Example("""
            enum Rule
            {

            }
            """): Example("""
                enum Rule {

                }
                """),
        Example("""
            enum Rule: E  {

            }
            """): Example("""
                enum Rule: E {

                }
                """),
        Example("""
            extension Rule
            {

            }
            """): Example("""
                extension Rule {

                }
                """),
        Example("""
            protocol Rule  {

            }
            """): Example("""
                protocol Rule {

                }
                """),
        Example("""
            struct Rule
            {

            }
            """): Example("""
                struct Rule {

                }
                """),
        Example("""
            struct Rule  : A
            {

            }
            """): Example("""
                struct Rule  : A {

                }
                """),
        Example("""
            do {

            } catch
            {

            }
            """): Example("""
                do {

                } catch {

                }
                """),
        Example("""
            do {

            } catch MyError.unknown  {

            }
            """): Example("""
                do {

                } catch MyError.unknown {

                }
                """),
        Example("""
            do {

            } catch let error  {

            }
            """): Example("""
                do {

                } catch let error {

                }
                """),
        Example("""
            defer  {

            }
            """): Example("""
                defer {

                }
                """),
        Example("""
            do  {

            }
            """): Example("""
            do {

            }
            """),
        Example("""
            for a in b
            {

            }
            """): Example("""
            for a in b {

            }
            """),
        Example("""
            for a in b where a == c  {

            }
            """): Example("""
                for a in b where a == c {

                }
                """),
        Example("""
            guard a == b else
            {
              return ""
            }
            """): Example("""
                guard a == b else {
                  return ""
                }
                """),
        Example("if\n\tlet a = b,\n\tlet c = d{ }\n"): Example("if\n\tlet a = b,\n\tlet c = d { }\n"),
        Example("""
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self)
            { // Complex or collection type
                return .visitChildren
            }
            """): Example("""
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                    || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                    || !node.type.is(SimpleTypeIdentifierSyntax.self) { // Complex or collection type
                    return .visitChildren
                }
                """),
        Example("""
            repeat  {

            } while a
            """): Example("""
                repeat {

                } while a
                """),
        Example("""
            while a  {

            }
            """): Example("""
                while a {

                }
                """),
        Example("class Rule{}"): Example("class Rule {}"),
        Example("actor Rule{}"): Example("actor Rule {}"),
        Example("enum Rule{}"): Example("enum Rule {}"),
        Example("protocol Rule{}"): Example("protocol Rule {}"),
        Example("extension Rule{}"): Example("extension Rule {}"),
        Example("""
            class Rule {
              var a: String {
                willSet{

                }
              }
            }
            """): Example("""
                class Rule {
                  var a: String {
                    willSet {

                    }
                  }
                }
                """),
        Example("""
            class Rule {
              var a: String {
                didSet  {

                }
              }
            }
            """): Example("""
                class Rule {
                  var a: String {
                    didSet {

                    }
                  }
                }
                """),
        Example("""
            precedencegroup Group{
              assignment: true
            }
            """): Example("""
                precedencegroup Group {
                  assignment: true
                }
                """),
        Example("""
            if c /* comment */    {
                return
            }
        """): Example("""
                if c /* comment */ {
                    return
                }
            """),
        // https://github.com/realm/SwiftLint/issues/5598
        Example("""
            if c    // A comment
            {
                return
            }
        """): Example("""
                if c { // A comment
                    return
                }
            """),
        // https://github.com/realm/SwiftLint/issues/5751
        Example("""
            if c    // A comment
            { // Another comment
                return
            }
        """): Example("""
                if c { // A comment // Another comment
                    return
                }
            """),
        // https://github.com/realm/SwiftLint/issues/5751
        Example("""
            func foo() {
                if q1, q2
                {
                    do1()
                } else if q3, q4
                {
                    do2()
                }
            }
            """): Example("""
                func foo() {
                    if q1, q2 {
                        do1()
                    } else if q3, q4 {
                        do2()
                    }
                }
                """),
        Example("""
            if
                "test".isEmpty
            // swiftlint:disable:next opening_brace
            {
                // code here
            }
            """): Example("""
                if
                    "test".isEmpty
                // swiftlint:disable:next opening_brace
                {
                    // code here
                }
                """),
    ]
}
