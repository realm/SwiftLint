internal struct AccessibilityFontSizeRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct TestView: View {
            var body: some View {
                Text("Hello World!")
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                Text("Hello World!")
                    .font(.system(.largeTitle))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                TextField("Username", text: .constant(""))
                    .font(.system(.largeTitle))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                SecureField("Password", text: .constant(""))
                    .font(.system(.largeTitle))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                Button("Login") {}
                    .font(.system(.largeTitle))
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Text("Hello World!")
                    .font(.system(size: 20))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Text("Hello World!")
                    .italic()
                    .font(.system(size: 20))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓TextField("Username", text: .constant(""))
                    .font(.system(size: 15))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓SecureField("Password", text: .constant(""))
                    .font(.system(size: 15))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Button("Login") {}
                    .font(.system(size: 15))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Text("Hello World!")
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Text("Hello World!")
                    .italic()
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓TextField("Username", text: .constant(""))
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓TextField("Username", text: .constant(""))
                    .italic()
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓SecureField("Password", text: .constant(""))
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓SecureField("Password", text: .constant(""))
                    .italic()
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Button("Login") {}
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """),
        Example("""
        struct TestView: View {
            var body: some View {
                ↓Button("Login") {}
                    .italic()
                    .font(.custom("Havana", fixedSize: 16))
            }
        }
        """)
    ]
}
