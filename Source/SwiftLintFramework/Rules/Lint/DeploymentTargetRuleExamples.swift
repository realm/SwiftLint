internal enum DeploymentTargetRuleExamples {
    static let nonTriggeringExamples: [Example] = {
        let commonExamples = [
            Example("@available(iOS 12.0, *)\nclass A {}"),
            Example("@available(watchOS 4.0, *)\nclass A {}"),
            Example("@available(swift 3.0.2)\nclass A {}"),
            Example("class A {}"),
            Example("if #available(iOS 10.0, *) {}"),
            Example("if #available(iOS 10, *) {}"),
            Example("guard #available(iOS 12.0, *) else { return }")
        ]

        guard SwiftVersion.current >= .fiveDotSix else {
            return commonExamples
        }

        return commonExamples + [
            Example("#if #unavailable(iOS 15.0) {}"),
            Example("#guard #unavailable(iOS 15.0) {} else { return }")
        ]
    }()

    static let triggeringExamples: [Example] = {
        let commonExamples = [
            Example("↓@available(iOS 6.0, *)\nclass A {}"),
            Example("↓@available(iOS 7.0, *)\nclass A {}"),
            Example("↓@available(iOS 6, *)\nclass A {}"),
            Example("↓@available(iOS 6.0, macOS 10.12, *)\n class A {}"),
            Example("↓@available(macOS 10.12, iOS 6.0, *)\n class A {}"),
            Example("↓@available(macOS 10.7, *)\nclass A {}"),
            Example("↓@available(OSX 10.7, *)\nclass A {}"),
            Example("↓@available(watchOS 0.9, *)\nclass A {}"),
            Example("↓@available(tvOS 8, *)\nclass A {}"),
            Example("if ↓#available(iOS 6.0, *) {}"),
            Example("if ↓#available(iOS 6, *) {}"),
            Example("guard ↓#available(iOS 6.0, *) else { return }")
        ]

        guard SwiftVersion.current >= .fiveDotSix else {
            return commonExamples
        }

        return commonExamples + [
            Example("if ↓#unavailable(iOS 7.0) {}"),
            Example("if ↓#unavailable(iOS 6.9) {}"),
            Example("guard ↓#unavailable(iOS 7.0) {} else { return }")
        ]
    }()
}
