extension ExportedImportsResolver {
    private static let optionsWithValue: Set<String> = [
        "-I",
        "-F",
        "-iframework",
        "-sdk",
        "-target",
        "-resource-dir",
        "-module-cache-path",
        "-swift-version",
        "-language-mode",
    ]

    private static let clangSearchPathOptions: Set<String> = [
        "-I",
        "-F",
        "-iframework",
    ]

    func compilerArgumentsForAPIDigester(
        _ arguments: [String]
    ) -> [String] {
        var result = [String]()
        var index = 0

        while index < arguments.count {
            if let consumed = appendClangSearchPath(
                from: arguments,
                at: index,
                to: &result
            ) {
                index += consumed
                continue
            }

            if let consumed = appendOptionWithValue(
                from: arguments,
                at: index,
                to: &result
            ) {
                index += consumed
                continue
            }

            appendJoinedSearchPath(
                arguments[index],
                to: &result
            )
            index += 1
        }

        return result
    }

    private func appendClangSearchPath(
        from arguments: [String],
        at index: Int,
        to result: inout [String]
    ) -> Int? {
        guard arguments[index] == "-Xcc" else {
            return nil
        }

        guard index + 1 < arguments.count else {
            return 1
        }

        let clangArgument = arguments[index + 1]

        if let separated = separatedClangSearchPath(
            from: arguments,
            at: index,
            option: clangArgument
        ) {
            result.append(separated.option)
            result.append(separated.value)
            return separated.consumed
        }

        appendJoinedSearchPath(
            clangArgument,
            to: &result
        )
        return 2
    }

    private func separatedClangSearchPath(
        from arguments: [String],
        at index: Int,
        option: String
    ) -> (option: String, value: String, consumed: Int)? {
        guard Self.clangSearchPathOptions.contains(option),
              index + 3 < arguments.count,
              arguments[index + 2] == "-Xcc" else {
            return nil
        }

        let value = arguments[index + 3]

        guard value.isNotEmpty,
              !value.hasPrefix("-") else {
            return nil
        }

        return (
            option: option,
            value: value,
            consumed: 4
        )
    }

    private func appendOptionWithValue(
        from arguments: [String],
        at index: Int,
        to result: inout [String]
    ) -> Int? {
        let option = arguments[index]

        guard Self.optionsWithValue.contains(option) else {
            return nil
        }

        guard index + 1 < arguments.count else {
            return 1
        }

        let value = arguments[index + 1]

        guard value.isNotEmpty,
              !value.hasPrefix("-") else {
            return 1
        }

        result.append(option)
        result.append(value)
        return 2
    }

    private func appendJoinedSearchPath(
        _ argument: String,
        to result: inout [String]
    ) {
        if argument.count > 2,
           argument.hasPrefix("-I") {
            result.append(argument)
        } else if argument.count > 2,
                  argument.hasPrefix("-F"),
                  !argument.hasPrefix("-Fsystem") {
            result.append(argument)
        } else if argument.count > "-iframework".count,
                  argument.hasPrefix("-iframework") {
            result.append(argument)
        }
    }
}
