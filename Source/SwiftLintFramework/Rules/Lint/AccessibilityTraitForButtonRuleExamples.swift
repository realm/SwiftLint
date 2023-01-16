internal struct AccessibilityTraitForButtonRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct MyView: View {
            var body: some View {
                Button {
                    print("tapped")
                } label: {
                    Text("Learn more")
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Link("Open link", destination: myUrl)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .onTapGesture {
                        print("tapped - open URL")
                    }
                    .accessibility(addTraits: .isLink)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .accessibility(addTraits: [.isButton, .isHeader])
                    .onTapGesture {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .onTapGesture {
                        print("tapped - open URL")
                    }
                    .accessibilityAddTraits([.isHeader, .isLink])
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .onTapGesture(count: 1) {
                        print("tapped")
                    }
                    .accessibility(addTraits: .isButton)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .onTapGesture(count: 1, perform: {
                        print("tapped")
                    })
                    .accessibility(addTraits: .isButton)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    // This rule does not include tap gestures with multiple taps for now.
                    // Custom gestures like this are also not very accessible, but require
                    // alternative ways to accomplish the same task with assistive tech.
                    .onTapGesture(count: 2) {
                        print("double-tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Label("Learn more", systemImage: "info.circle")
                    .onTapGesture(count: 1) {
                        print("tapped")
                    }
                    .accessibility(addTraits: .isButton)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .onTapGesture {
                    print("tapped")
                }
                // This modifier is not strictly required — each subview will inherit the button trait.
                // That said, grouping a tappable stack into a single element is a good way to reduce
                // the number of swipes required for a VoiceOver user to navigate the page.
                .accessibilityElement(children: .combine)
                .accessibility(addTraits: .isButton)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .gesture(TapGesture().onEnded {
                        print("tapped")
                    })
                    .accessibilityAddTraits(.isButton)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        print("tapped - open URL")
                    })
                    .accessibilityAddTraits(.isLink)
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .highPriorityGesture(TapGesture().onEnded {
                        print("tapped")
                    })
                    .accessibility(addTraits: [.isButton])
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                Text("Learn more")
                    .gesture(TapGesture(count: 2).onEnded {
                        print("tapped")
                    })
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .onTapGesture {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .accessibility(addTraits: .isHeader)
                    .onTapGesture {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .onTapGesture(count: 1) {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .onTapGesture(count: 1, perform: {
                        print("tapped")
                    })
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Label("Learn more", systemImage: "info.circle")
                    .onTapGesture(count: 1) {
                        print("tapped")
                    }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .onTapGesture {
                    print("tapped")
                }
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .gesture(TapGesture().onEnded {
                        print("tapped")
                    })
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        print("tapped")
                    })
            }
        }
        """),
        Example("""
        struct MyView: View {
            var body: some View {
                ↓Text("Learn more")
                    .highPriorityGesture(TapGesture().onEnded {
                        print("tapped")
                    })
            }
        }
        """)
    ]
}
