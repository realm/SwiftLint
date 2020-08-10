import SourceKittenFramework

public struct UnneededNotificationCenterRemovalRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unneeded_notification_center_removal",
        name: "Unneeded NotificationCenter Removal",
        description: "Observers are automatically unregistered on dealloc (iOS 9 / macOS 10.11) so you should't call " +
                     "`removeObserver(self)` in the deinit.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Example {
                deinit {
                    NotificationCenter.default.removeObserver(someOtherObserver)
                }
            }
            """),
            Example("""
            class Example {
                func removeObservers() {
                    NotificationCenter.default.removeObserver(self)
                }
            }
            """),
            Example("""
            class Example {
                deinit {
                    cleanup()
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo {
                deinit {
                    NotificationCenter.default.removeObserver(↓self)
                }
            }
            """)
            ,
            Example("""
            class Foo {
                deinit {
                    NotificationCenter.default.removeObserver(↓self,
                                                              name: UITextView.textDidChangeNotification, object: nil)
                }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .class else { return [] }

        let methodCollector = NamespaceCollector(dictionary: dictionary)
        let methods = methodCollector.findAllElements(of: [.functionMethodInstance])
        let deinitMethod = methods.first(where: { $0.name == "deinit" })

        return deinitMethod?.dictionary.substructure.compactMap { subDict -> StyleViolation? in
            guard subDict.expressionKind == .call else { return nil }

            return violationRange(in: file, dictionary: subDict).map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0.location))
            }
        } ?? []
    }

    private func violationRange(in file: SwiftLintFile, dictionary: SourceKittenDictionary) -> ByteRange? {
        guard
            dictionary.name == "NotificationCenter.default.removeObserver",
            let observerRange = firstArgumentBody(in: dictionary),
            let observerName = file.stringView.substringWithByteRange(observerRange),
            observerName == "self"
            else { return nil }

        return observerRange
    }

    /// observer parameter range
    private func firstArgumentBody(in dictionary: SourceKittenDictionary) -> ByteRange? {
        if dictionary.enclosedArguments.names == [nil, "name", "object"],
            let bodyOffset = dictionary.enclosedArguments.first?.bodyOffset,
            let bodyLength = dictionary.enclosedArguments.first?.bodyLength {
            return ByteRange(location: bodyOffset, length: bodyLength)
        } else if dictionary.enclosedArguments.isEmpty,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength {
            return ByteRange(location: bodyOffset, length: bodyLength)
        } else {
            return nil
        }
    }
}

private extension Array where Element == SourceKittenDictionary {
    var names: [String?] {
        return map { $0.name }
    }
}
