import SourceKittenFramework

/// Struct to represent SwiftUI ViewModifiers for the purpose of finding modifiers in a substructure.
struct SwiftUIModifier {
    /// Name of the modifier.
    let name: String

    /// List of arguments to check for in the modifier.
    let arguments: [Argument]

    struct Argument {
        /// Name of the argument we want to find. For single unnamed arguments, use the empty string.
        let name: String

        /// Whether or not the argument is required. If the argument is present, value checks are enforced.
        /// Allows for better handling of modifiers with default values for certain arguments where we want
        /// to ensure that the default value is used.
        let required: Bool

        /// List of possible values for the argument. Typically should just be a list with a single element,
        /// but allows for the flexibility of checking for multiple possible values. To only check for the presence
        /// of the modifier and not enforce any certain values, pass an empty array. All values are parsed as
        /// Strings; for other types (boolean, numeric, optional, etc) types you can check for "true", "5", "nil", etc.
        let values: [String]

        /// Success criteria used for matching values (prefix, suffix, substring, exact match, or none).
        let matchType: MatchType

        init(name: String, required: Bool = true, values: [String], matchType: MatchType = .exactMatch) {
            self.name = name
            self.required = required
            self.values = values
            self.matchType = matchType
        }
    }

    enum MatchType {
        case prefix, suffix, substring, exactMatch

        /// Compares the parsed argument value to a target value for the given match type
        /// and returns true is a match is found.
        func matches(argumentValue: String, targetValue: String) -> Bool {
            switch self {
            case .prefix:
                return argumentValue.hasPrefix(targetValue)
            case .suffix:
                return argumentValue.hasSuffix(targetValue)
            case .substring:
                return argumentValue.contains(targetValue)
            case .exactMatch:
                return argumentValue == targetValue
            }
        }
    }
}

/// Extensions for recursively checking SwiftUI code for certain modifiers.
extension SourceKittenDictionary {
    /// Call on a SwiftUI View to recursively check the substructure for a certain modifier with certain arguments.
    /// - Parameters:
    ///   - modifiers: A list of `SwiftUIModifier` structs to check for in the view's substructure.
    ///                In most cases, this can just be a single modifier, but since some modifiers have
    ///                multiple versions, this enables checking for any modifier from the list.
    ///   - file: The SwiftLintFile object for the current file, used to extract argument values.
    /// - Returns: A boolean value representing whether or not the given modifier with the specified
    ///            arguments appears in the view's substructure.
    func hasModifier(anyOf modifiers: [SwiftUIModifier], in file: SwiftLintFile) -> Bool {
        // SwiftUI ViewModifiers are treated as `call` expressions, and we make sure we can get the expression's name.
        guard expressionKind == .call, let name else {
            return false
        }

        // If any modifier from the list matches, return true.
        for modifier in modifiers {
            // Check for the given modifier name
            guard name.hasSuffix(modifier.name) else {
                continue
            }

            // Check arguments.
            var matchesArgs = true
            for argument in modifier.arguments {
                var foundArg = false
                var argValue: String?

                // Check for single unnamed argument.
                if argument.name.isEmpty {
                    foundArg = true
                    argValue = getSingleUnnamedArgumentValue(in: file)
                } else if let parsedArgument = enclosedArguments.first(where: { $0.name == argument.name }) {
                    foundArg = true
                    argValue = parsedArgument.getArgumentValue(in: file)
                }

                // If argument is not required and we didn't find it, continue.
                if !foundArg && !argument.required {
                    continue
                }

                // Otherwise, we must have found an argument with a non-nil value to continue.
                guard foundArg, let argumentValue = argValue else {
                    matchesArgs = false
                    break
                }

                // Argument value can match any of the options given in the argument struct.
                if argument.values.isEmpty || argument.values.contains(where: {
                    argument.matchType.matches(argumentValue: argumentValue, targetValue: $0)
                }) {
                    // Found a match, continue to next argument.
                    continue
                } else {
                    // Did not find a match, exit loop over arguments.
                    matchesArgs = false
                    break
                }
            }

            // Return true if all arguments matched
            if matchesArgs {
                return true
            }
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibility(hidden: true).frame
        //   --> Image("myImage").resizable().accessibility
        //     --> Image("myImage").resizable
        //       --> Image
        return substructure.contains(where: { $0.hasModifier(anyOf: modifiers, in: file) })
    }

    // MARK: Sample use cases of `hasModifier` that are used in multiple rules

    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityHidden(true)`
    /// or `accessibility(hidden: true)` modifier.
    func hasAccessibilityHiddenModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "accessibilityHidden",
                    arguments: [.init(name: "", values: ["true"])]
                ),
                SwiftUIModifier(
                    name: "accessibility",
                    arguments: [.init(name: "hidden", values: ["true"])]
                )
            ],
            in: file
        )
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `accessibilityElement()` or
    /// `accessibilityElement(children: .ignore)` modifier (`.ignore` is the default parameter value).
    func hasAccessibilityElementChildrenIgnoreModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "accessibilityElement",
                    arguments: [.init(name: "children", required: false, values: [".ignore"], matchType: .suffix)]
                )
            ],
            in: file
        )
    }

    // MARK: Helpers to extract argument values

    /// Helper to get the value of an argument.
    func getArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .argument, let bodyByteRange else {
            return nil
        }

        return file.stringView.substringWithByteRange(bodyByteRange)
    }

    /// Helper to get the value of a single unnamed argument to a function call.
    func getSingleUnnamedArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .call, let bodyByteRange else {
            return nil
        }

        return file.stringView.substringWithByteRange(bodyByteRange)
    }
}
