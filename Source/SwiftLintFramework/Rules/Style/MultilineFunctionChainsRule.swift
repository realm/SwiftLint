import Foundation
import SourceKittenFramework

public struct MultilineFunctionChainsRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_function_chains",
        name: "Multiline Function Chains",
        description: "Chained function calls should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: [
            "let evenSquaresSum = [20, 17, 35, 4].filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
            """
            let evenSquaresSum = [20, 17, 35, 4]
                .filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
            """,
            """
            let chain = a
                .b(1, 2, 3)
                .c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c { blah in print(blah) }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c(.init(
                    a: 1,
                    b, 2,
                    c, 3))
                .d()
            """,
            """
            self.viewModel.outputs.postContextualNotification
              .observeForUI()
              .observeValues {
                NotificationCenter.default.post(
                  Notification(
                    name: .ksr_showNotificationsDialog,
                    userInfo: [UserInfoKeys.context: PushNotificationDialog.Context.pledge,
                               UserInfoKeys.viewController: self]
                 )
                )
              }
            """,
            "let remainingIDs = Array(Set(self.currentIDs).subtracting(Set(response.ids)))",
            """
            self.happeningNewsletterOn = self.updateCurrentUser
                .map { $0.newsletters.happening }.skipNil().skipRepeats()
            """
        ],
        triggeringExamples: [
            """
            let evenSquaresSum = [20, 17, 35, 4]
                .filter { $0 % 2 == 0 }↓.map { $0 * $0 }
                .reduce(0, +)
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)
                .c { blah in
                    print(blah)
                }↓.d()
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)
                .c(2, 3, 4)↓.d()
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)↓.c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            a.b {
            //  ““
            }↓.e()
            """
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violatingOffsets(file: file, kind: kind, dictionary: dictionary).map { offset in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: offset))
        }
    }

    private func violatingOffsets(file: SwiftLintFile,
                                  kind: SwiftExpressionKind,
                                  dictionary: SourceKittenDictionary) -> [Int] {
        let ranges = callRanges(file: file, kind: kind, dictionary: dictionary)

        let calls = ranges.compactMap { range -> (dotLine: Int, dotOffset: Int, range: NSRange)? in
            guard
                let offset = callDotOffset(file: file, callRange: range),
                let line = file.linesContainer.lineAndCharacter(forCharacterOffset: offset)?.line else {
                    return nil
            }
            return (dotLine: line, dotOffset: offset, range: range)
        }

        let uniqueLines = calls.map { $0.dotLine }.unique

        if uniqueLines.count == 1 { return [] }

        // The first call (last here) is allowed to not have a leading newline.
        let noLeadingNewlineViolations = calls
            .dropLast()
            .filter { line in
                !callHasLeadingNewline(file: file, callRange: line.range)
            }

        return noLeadingNewlineViolations.map { $0.dotOffset }
    }

    private static let whitespaceDotRegex = regex("\\s*\\.")

    private func callDotOffset(file: SwiftLintFile, callRange: NSRange) -> Int? {
        guard
            let range = file.linesContainer.byteRangeToNSRange(start: callRange.location, length: callRange.length),
            case let regex = type(of: self).whitespaceDotRegex,
            let match = regex.matches(in: file.contents, options: [], range: range).last?.range else {
                return nil
        }
        return match.location + match.length - 1
    }

    private static let newlineWhitespaceDotRegex = regex("\\n\\s*\\.")

    private func callHasLeadingNewline(file: SwiftLintFile, callRange: NSRange) -> Bool {
        guard
            let range = file.linesContainer.byteRangeToNSRange(start: callRange.location, length: callRange.length),
            case let regex = type(of: self).newlineWhitespaceDotRegex,
            regex.firstMatch(in: file.contents, options: [], range: range) != nil else {
                return false
        }
        return true
    }

    private func callRanges(file: SwiftLintFile,
                            kind: SwiftExpressionKind,
                            dictionary: SourceKittenDictionary,
                            parentCallName: String? = nil) -> [NSRange] {
        guard
            kind == .call,
            case let contents = file.linesContainer,
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength,
            let name = contents.substringWithByteRange(start: offset, length: length) else {
                return []
        }

        let subcalls = dictionary.subcalls

        if subcalls.isEmpty, let parentCallName = parentCallName, parentCallName.starts(with: name) {
            return [NSRange(location: offset, length: length)]
        }

        return subcalls.flatMap { call -> [NSRange] in
            // Bail out early if there's no subcall, since this means there's no chain.
            guard let range = subcallRange(file: file, call: call, parentName: name, parentNameOffset: offset) else {
                return []
            }

            return [range] + callRanges(file: file, kind: .call, dictionary: call, parentCallName: name)
        }
    }

    private func subcallRange(file: SwiftLintFile,
                              call: SourceKittenDictionary,
                              parentName: String,
                              parentNameOffset: Int) -> NSRange? {
        guard
            case let contents = file.linesContainer,
            let nameOffset = call.nameOffset,
            parentNameOffset == nameOffset,
            let nameLength = call.nameLength,
            let bodyOffset = call.bodyOffset,
            let bodyLength = call.bodyLength,
            let name = contents.substringWithByteRange(start: nameOffset, length: nameLength),
            parentName.starts(with: name) else {
                return nil
        }

        let nameEndOffset = nameOffset + nameLength
        let nameLengthDifference = parentName.utf8.count - nameLength
        let offsetDifference = bodyOffset - nameEndOffset

        return NSRange(location: nameEndOffset + offsetDifference + bodyLength,
                       length: nameLengthDifference - bodyLength - offsetDifference)
    }
}

private extension SourceKittenDictionary {
    var subcalls: [SourceKittenDictionary] {
        return substructure.compactMap { dictionary -> SourceKittenDictionary? in
            guard dictionary.expressionKind == .call else {
                return nil
            }
            return dictionary
        }
    }
}
