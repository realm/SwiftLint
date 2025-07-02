// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
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
        """),
        // MARK: - SwiftSyntax Migration Regression Tests
        // These examples would have been false positives with the SourceKit implementation
        // but now correctly pass with the SwiftSyntax implementation
        Example("""
        struct MyView: View {
            var body: some View {
                NavigationLink("Go to Details") {
                    DetailView()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Navigate Here")
                    }
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Button("Save Changes") {
                    saveAction()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Button(action: performAction) {
                    HStack {
                        Image(uiImage: UIImage(systemName: "star") ?? UIImage())
                        Text("Favorite")
                    }
                }
                .accessibilityLabel("Add to Favorites")
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                VStack {
                    Image(systemName: "wifi")
                    Image("network-icon")
                    Text("Network Status")
                }.accessibilityElement(children: .ignore)
                .accessibilityLabel("Connected to WiFi")
            }
        }
        """),
        Example("""
        struct MyView: View {
            let statusImage: UIImage
            var body: some View {
                HStack {
                    Image(uiImage: statusImage)
                        .foregroundColor(.green)
                    Text("System Status")
                }.accessibilityElement(children: .ignore)
                .accessibilityLabel("System is operational")
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image(nsImage: NSImage(named: "gear") ?? NSImage())
                        Text("Preferences")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Button {
                    toggleState()
                } label: {
                    Image(systemName: isEnabled ? "eye" : "eye.slash")
                        .foregroundColor(isEnabled ? .blue : .gray)
                }
                .accessibilityLabel(isEnabled ? "Hide content" : "Show content")
            }
        }
        """),
        Example("""
        struct CustomCard: View {
            var body: some View {
                VStack {
                    Image("card-background")
                    Image(systemName: "checkmark.circle")
                    Text("Task Complete")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Task completed successfully")
            }
        }
        """),
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
        """),
        // MARK: - SwiftSyntax Migration Detection Improvements
        // These violations would have been missed by the SourceKit implementation
        // but are now correctly detected by SwiftSyntax
        Example("""
        struct StatusView: View {
            let statusIcon: UIImage
            var body: some View {
                HStack {
                    ↓Image(uiImage: statusIcon)
                        .foregroundColor(.green)
                    Text("Status")
                }
            }
        }
        """),
        Example("""
        struct PreferencesView: View {
            var body: some View {
                VStack {
                    ↓Image(nsImage: NSImage(named: "gear") ?? NSImage())
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Settings")
                }
            }
        }
        """),
        Example("""
        struct FaviconView: View {
            let favicon: UIImage?
            var body: some View {
                ↓Image(uiImage: favicon ?? UIImage())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        """),
        Example("""
        struct IconGrid: View {
            var body: some View {
                HStack {
                    ↓Image(uiImage: loadedImage)
                        .resizable()
                    ↓Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }.accessibilityElement(children: .combine)
            }
        }
        """),
        Example("""
        struct CardView: View {
            var body: some View {
                VStack {
                    ↓Image(uiImage: backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    Text("Card Content")
                }.accessibilityElement(children: .contain)
            }
        }
        """),
    ]
}
