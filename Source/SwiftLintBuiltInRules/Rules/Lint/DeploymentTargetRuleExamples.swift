internal enum DeploymentTargetRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        "@available(iOS 12.0, *)\nclass A {}",
        "@available(iOSApplicationExtension 13.0, *)\nclass A {}",
        "@available(watchOS 4.0, *)\nclass A {}",
        "@available(watchOSApplicationExtension 4.0, *)\nclass A {}",
        "@available(swift 3.0.2)\nclass A {}",
        "class A {}",
        "if #available(iOS 10.0, *) {}",
        "if #available(iOS 10, *) {}",
        "guard #available(iOS 12.0, *) else { return }",
        "#if #unavailable(iOS 15.0) {}",
        "#guard #unavailable(iOS 15.0) {} else { return }"
    ]

    static let triggeringExamples: [Example] = [
        "↓@available(iOS 6.0, *)\nclass A {}",
        "↓@available(iOSApplicationExtension 6.0, *)\nclass A {}",
        "↓@available(iOS 7.0, *)\nclass A {}",
        "↓@available(iOS 6, *)\nclass A {}",
        "↓@available(iOS 6.0, macOS 10.12, *)\n class A {}",
        "↓@available(macOS 10.12, iOS 6.0, *)\n class A {}",
        "↓@available(macOS 10.7, *)\nclass A {}",
        "↓@available(macOSApplicationExtension 10.7, *)\nclass A {}",
        "↓@available(OSX 10.7, *)\nclass A {}",
        "↓@available(watchOS 0.9, *)\nclass A {}",
        "↓@available(watchOSApplicationExtension 0.9, *)\nclass A {}",
        "↓@available(tvOS 8, *)\nclass A {}",
        "↓@available(tvOSApplicationExtension 8, *)\nclass A {}",
        "if ↓#available(iOS 6.0, *) {}",
        "if ↓#available(iOS 6, *) {}",
        "guard ↓#available(iOS 6.0, *) else { return }",
        "if ↓#unavailable(iOS 7.0) {}",
        "if ↓#unavailable(iOS 6.9) {}",
        "guard ↓#unavailable(iOS 7.0) {} else { return }"
    ]
}
