internal struct AccessibilityLabelForImageRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct MyView: View {
            var body: some View {
                Image(decorative: "my-image")
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image("my-image", label: Text("Alt text for my image"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibility(hidden: true)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibilityHidden(true)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibility(label: Text("Alt text for my image"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibilityLabel(Text("Alt text for my image"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .renderingMode(.template)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .accessibilityLabel(Text("Alt text for my image"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(true)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    Image(decorative: "my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image"))
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image"))
                }.accessibilityElement()
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image"))
                }.accessibilityHidden(true)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                HStack(spacing: 8) {
                    Image(decorative: "my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Text("Text to accompany my image")
                }.accessibilityElement(children: .combine)
                .padding(16)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                HStack(spacing: 8) {
                    Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Text("Text to accompany my image")
                }.accessibilityElement(children: .ignore)
                .padding(16)
                .accessibilityLabel(Text("Label for my image and text"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Button(action: { doAction() }) {
                    Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel(Text("Label for my image"))
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Image("my-image")
                    .resizable(true)
                    .frame(width: 48, height: 48)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Image(uiImage: myUiImage)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(false)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .accessibilityLabel(Text("Alt text for my image"))
                ↓Image("other image")
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Image(decorative: "image1")
                ↓Image("image2")
                Image(uiImage: "image3")
                    .accessibility(label: Text("a pretty picture"))
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    Image(decorative: "my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    ↓Image("my-image")
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    ↓Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image"))
                }.accessibilityElement(children: .contain)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    ↓Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image"))
                }.accessibilityHidden(false)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                HStack(spacing: 8) {
                    ↓Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                    Text("Text to accompany my image")
                }.accessibilityElement(children: .combine)
                .padding(16)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Button(action: { doAction() }) {
                    ↓Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Image(systemName: "circle.plus")
            }
        }
        """)
    ]
}
