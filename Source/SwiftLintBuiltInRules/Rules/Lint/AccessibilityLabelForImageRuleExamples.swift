// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
internal struct AccessibilityLabelForImageRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        struct MyView: View {
            var body: some View {
                Image(decorative: "my-image")
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image("my-image", label: Text("Alt text for my image"))
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibility(hidden: true)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibilityHidden(true)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibility(label: Text("Alt text for my image"))
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image("my-image")
                    .accessibilityLabel(Text("Alt text for my image"))
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .renderingMode(.template)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .accessibilityLabel(Text("Alt text for my image"))
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(true)
            }
        }
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        // MARK: - SwiftSyntax Migration Regression Tests
        // These examples would have been false positives with the SourceKit implementation
        // but now correctly pass with the SwiftSyntax implementation
        """
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
        """,
        """
        struct MyView: View {
            var body: some View {
                Button("Save Changes") {
                    saveAction()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }
        }
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        // MARK: - Label icon closure exemptions
        // Images inside a Label's icon: closure are inherently labeled by the Label's text content.
        """
        struct MyView: View {
            var body: some View {
                Label {
                    Text("Connected")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Label(content: { Text("Download") }, icon: { Image("custom-download-icon") })
            }
        }
        """,
    ])

    static let triggeringExamples = #examples([
        """
        struct MyView: View {
            var body: some View {
                ↓Image("my-image")
                    .resizable(true)
                    .frame(width: 48, height: 48)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                ↓Image(uiImage: myUiImage)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                ↓SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(false)
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image(uiImage: myUiImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .accessibilityLabel(Text("Alt text for my image"))
                ↓Image("other image")
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                Image(decorative: "image1")
                ↓Image("image2")
                Image(uiImage: "image3")
                    .accessibility(label: Text("a pretty picture"))
            }
        }
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
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
        """,
        """
        struct MyView: View {
            var body: some View {
                Button(action: { doAction() }) {
                    ↓Image("my-image")
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                }
            }
        }
        """,
        """
        struct MyView: View {
            var body: some View {
                ↓Image(systemName: "circle.plus")
            }
        }
        """,
        // MARK: - SwiftSyntax Migration Detection Improvements
        // These violations would have been missed by the SourceKit implementation
        // but are now correctly detected by SwiftSyntax
        """
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
        """,
        """
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
        """,
        """
        struct FaviconView: View {
            let favicon: UIImage?
            var body: some View {
                ↓Image(uiImage: favicon ?? UIImage())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        """,
        """
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
        """,
        """
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
        """,
    ])
}
