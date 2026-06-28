internal struct PrivateSwiftUIStatePropertyRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        """
        struct MyApp: App {
            @State private var isPlaying: Bool = false
        }
        """,
        """
        struct MyScene: Scene {
            @State private var isPlaying: Bool = false
        }
        """,
        """
        struct CofntentView: View {
            @State private var isPlaying: Bool = false
        }
        """,
        """
        struct ContentView: View {
            @State private var isPlaying: Bool = false

            struct InnerView: View {
                @State private var showsIndicator: Bool = false
            }
        }
        """,
        """
        struct MyStruct {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
        }
        """,
        """
        struct MyStruct {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }

            @State var nonTriggeringState: Bool = false
        }
        """,
        """
        struct ContentView: View {
            var s: Int {
                @State
                var s: Int = 3
                return s
            }

            var body: some View { Text("") }
        }
        """,
        """
        struct ContentView: View {
            var isPlaying = false
        }
        """,
        """
        struct MyApp: App {
            @StateObject private var model = DataModel()
        }
        """,
        """
        struct MyScene: Scene {
            @StateObject private var model = DataModel()
        }
        """,
        """
        struct ContentView: View {
            @StateObject private var model = DataModel()
        }
        """,
        """
        struct MyStruct {
            struct ContentView: View {
                @StateObject private var dataModel = DataModel()
            }

            @StateObject var nonTriggeringObject = MyModel()
        }
        """,
        """
        struct Foo {
            @State var bar = false
        }
        """,
        """
        class Foo: ObservableObject {
            @State var bar = Bar()
        }
        """,
        """
        extension MyObject {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
        }
        """,
        """
        actor ContentView: View {
            @State private var isPlaying: Bool = false
        }
        """,
        """
        struct ContentViewModifier: ViewModifier {
            @State private var isPlaying = false
        }
        """,
    ])

    static let triggeringExamples: [Example] = #examples([
        """
        struct MyApp: App {
            @State ↓var isPlaying: Bool = false
        }
        """,
        """
        struct MyScene: Scene {
            @State ↓public var isPlaying: Bool = false
        }
        """,
        """
        struct ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """,
        """
        struct ContentView: View {
            struct InnerView: View {
                @State private var showsIndicator: Bool = false
            }

            @State ↓var isPlaying: Bool = false
        }
        """,
        """
        struct MyStruct {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
        }
        """,
        """
        struct MyStruct {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }

            @State var isPlaying: Bool = false
        }
        """,
        """
        final class ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """,
        """
        extension MyObject {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
        }
        """,
        """
        actor ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """,
        """
        struct MyApp: App {
            @StateObject ↓var model = DataModel()
        }
        """,
        """
        struct MyScene: Scene {
            @StateObject ↓var model = DataModel()
        }
        """,
        """
        struct ContentView: View {
            @StateObject ↓var model = DataModel()
        }
        """,
        """
        struct ContentView: View {
            @State ↓private(set) var isPlaying = false
        """,
        """
        struct ContentView: View {
            @State ↓fileprivate(set) public var isPlaying = false
        """,
        """
        struct ContentViewModifier: ViewModifier {
            @State ↓var isPlaying = false
        }
        """,
    ])

    static let corrections: [Example: Example] = #examplesDictionary([
        """
        struct ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """: """
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """,
        """
        struct ContentView: View {
            @State public ↓var isPlaying: Bool = false
        }
        """: """
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """,
        """
        struct ContentView: View {
            @State private(set) ↓var isPlaying: Bool = false
        }
        """: """
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """,
        """
        struct ContentView: View {
            @State
            /// This will track if the content is currently playing
            private(set)
            // This is another comment about this property
            public ↓var isPlaying: Bool = false
        }
        """: """
                        struct ContentView: View {
                            @State
                            /// This will track if the content is currently playing
                            // This is another comment about this property
                            private var isPlaying: Bool = false
                        }
                        """,
        """
        struct MyApp: App {
            @State
            /// This will track if the content is currently playing
            ↓var isPlaying: Bool = false
        }
        """: """
                        struct MyApp: App {
                            @State
                            /// This will track if the content is currently playing
                            private var isPlaying: Bool = false
                        }
                        """,
        """
        struct MyScene: Scene {
            @State /* This is a comment */ ↓var isPlaying: Bool = false
        }
        """: """
                        struct MyScene: Scene {
                            @State /* This is a comment */ private var isPlaying: Bool = false
                        }
                        """,
        """
        struct ContentView: View {
            @State
            /// This will track if the content is currently playing
            ↓var isPlaying: Bool = false
        }
        """: """
                        struct ContentView: View {
                            @State
                            /// This will track if the content is currently playing
                            private var isPlaying: Bool = false
                        }
                        """,
    ])
}
