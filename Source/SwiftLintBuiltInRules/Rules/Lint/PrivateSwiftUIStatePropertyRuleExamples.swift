internal struct PrivateSwiftUIStatePropertyRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        struct MyApp: App {
            @State private var isPlaying: Bool = false
        }
        """),
        Example("""
        struct MyScene: Scene {
            @State private var isPlaying: Bool = false
        }
        """),
        Example("""
        struct CofntentView: View {
            @State private var isPlaying: Bool = false
        }
        """),
        Example("""
        struct ContentView: View {
            @State fileprivate var isPlaying: Bool = false
        }
        """),
        Example("""
        struct ContentView: View {
            @State private var isPlaying: Bool = false

            struct InnerView: View {
                @State private var showsIndicator: Bool = false
            }
        }
        """),
        Example("""
        struct MyStruct {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
        }
        """),
        Example("""
        struct MyStruct {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }

            @State var nonTriggeringState: Bool = false
        }
        """),

        Example("""
        struct ContentView: View {
            var isPlaying = false
        }
        """),
        Example("""
        struct MyApp: App {
            @StateObject private var model = DataModel()
        }
        """),
        Example("""
        struct MyScene: Scene {
            @StateObject private var model = DataModel()
        }
        """),
        Example("""
        struct ContentView: View {
            @StateObject private var model = DataModel()
        }
        """),
        Example("""
        struct MyStruct {
            struct ContentView: View {
                @StateObject private var dataModel = DataModel()
            }

            @StateObject var nonTriggeringObject = MyModel()
        }
        """),
        Example("""
        struct Foo {
            @State var bar = false
        }
        """),
        Example("""
        class Foo: ObservableObject {
            @State var bar = Bar()
        }
        """),
        Example("""
        extension MyObject {
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
        }
        """),
        Example("""
        actor ContentView: View {
            @State private var isPlaying: Bool = false
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        struct MyApp: App {
            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        struct MyScene: Scene {
            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        struct ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        struct ContentView: View {
            struct InnerView: View {
                @State private var showsIndicator: Bool = false
            }

            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        struct MyStruct {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
        }
        """),
        Example("""
        struct MyStruct {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }

            @State var isPlaying: Bool = false
        }
        """),
        Example("""
        final class ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        extension MyObject {
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
        }
        """),
        Example("""
        actor ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """),
        Example("""
        struct MyApp: App {
            @StateObject ↓var model = DataModel()
        }
        """),
        Example("""
        struct MyScene: Scene {
            @StateObject ↓var model = DataModel()
        }
        """),
        Example("""
        struct ContentView: View {
            @StateObject ↓var model = DataModel()
        }
        """),
        Example("""
        struct ContentView: View {
            @State private(set) ↓var isPlaying = false
        """),
        Example("""
        struct ContentView: View {
            @State fileprivate(set) ↓var isPlaying = false
        """)
    ]

    static let corrections: [Example: Example] = [
        Example("""
        struct ContentView: View {
            @State ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """),
        Example("""
        struct MyApp: App {
            @State ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct MyApp: App {
                            @State private var isPlaying: Bool = false
                        }
                        """),
        Example("""
        struct MyScene: Scene {
            @State ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct MyScene: Scene {
                            @State private var isPlaying: Bool = false
                        }
                        """),
        Example("""
        struct ContentView: View {
            @State
            ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct ContentView: View {
                            @State
                            private var isPlaying: Bool = false
                        }
                        """),
        Example("""
        struct ContentView: View {
            @State private(set) ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """),
        Example("""
        struct ContentView: View {
            @State fileprivate(set) ↓var isPlaying: Bool = false
        }
        """): Example("""
                        struct ContentView: View {
                            @State private var isPlaying: Bool = false
                        }
                        """)
    ]
}
