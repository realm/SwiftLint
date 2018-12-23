import Foundation
import SourceKittenFramework

public struct UntypedErrorInCatchRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let regularExpression =
        "catch" + // The catch keyword
        "(?:"   + // Start of the first non-capturing group
        "\\s*"  + // Zero or multiple whitespace character
        "\\("   + // The `(` character
        "?"     + // Zero or one occurrence of the previous character
        "\\s*"  + // Zero or multiple whitespace character
        "(?:"   + // Start of the alternative non-capturing group
        "let"   + // `let` keyword
        "|"     + // OR
        "var"   + // `var` keyword
        ")"     + // End of the alternative non-capturing group
        "\\s+"  + // At least one any type of whitespace character
        "\\w+"  + // At least one any type of word character
        "\\s*"  + // Zero or multiple whitespace character
        "\\)"   + // The `)` character
        "?"     + // Zero or one occurrence of the previous character
        ")"     + // End of the first non-capturing group
        "(?:"   + // Start of the second non-capturing group
        "\\s*"  + // Zero or unlimited any whitespace character
        ")"     + // End of the second non-capturing group
        "\\{"     // Start scope character

    public static let description = RuleDescription(
        identifier: "untyped_error_in_catch",
        name: "Untyped Error in Catch",
        description: "Catch statements should not declare error variables without type casting.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            do {
              try foo()
            } catch {}
            """,
            """
            do {
              try foo()
            } catch Error.invalidOperation {
            } catch {}
            """,
            """
            do {
              try foo()
            } catch let error as MyError {
            } catch {}
            """,
            """
            do {
              try foo()
            } catch var error as MyError {
            } catch {}
            """
        ],
        triggeringExamples: [
            """
            do {
              try foo()
            } ↓catch var error {}
            """,
            """
            do {
              try foo()
            } ↓catch let error {}
            """,
            """
            do {
              try foo()
            } ↓catch let someError {}
            """,
            """
            do {
              try foo()
            } ↓catch var someError {}
            """,
            """
            do {
              try foo()
            } ↓catch let e {}
            """,
            """
            do {
              try foo()
            } ↓catch(let error) {}
            """,
            """
            do {
              try foo()
            } ↓catch (let error) {}
            """
        ],
        corrections: [
            "do {\n    try foo() \n} ↓catch let error {}": "do {\n    try foo() \n} catch {}",
            "do {\n    try foo() \n} ↓catch(let error) {}": "do {\n    try foo() \n} catch {}",
            "do {\n    try foo() \n} ↓catch (let error) {}": "do {\n    try foo() \n} catch {}"
        ])

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.location),
                                  reason: configuration.consoleDescription)
        }
    }

    fileprivate func violationRanges(in file: File) -> [NSRange] {
        return file.match(pattern: type(of: self).regularExpression,
                          with: [.keyword, .keyword, .identifier])
    }
}

extension UntypedErrorInCatchRule: CorrectableRule {
    public func correct(file: File) -> [Correction] {
        let violations = violationRanges(in: file)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var contents = file.contents.bridge()
        let description = type(of: self).description
        var corrections = [Correction]()

        for range in matches.reversed() where contents.substring(with: range).contains("let error") {
            contents = contents.replacingCharacters(in: range, with: "catch {").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents.bridge())
        return corrections
    }
}
