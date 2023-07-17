internal struct PrivateSwiftUIStatePropertyRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example(
            """
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
            """
        ),
        Example(
            """
            struct ContentView: View {
                @State fileprivate var isPlaying: Bool = false
            }
            """
        ),
        Example(
            """
            struct ContentView: View {
                var isPlaying = false
            }
            """
        ),
        Example(
            """
            struct ContentView: View {
                @StateObject var foo = Foo()
            }
            """
        )
    ]

    static let triggeringExamples: [Example] = [
        Example(
            """
            struct ContentView: View {
                @State var isPlaying: Bool = false
            }
            """
        )
    ]
}
