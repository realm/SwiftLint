import Commandant

func pathOption(action: String) -> Option<String> {
    return Option(key: "path",
                  defaultValue: "",
                  usage: "the path to the file or directory to \(action)")
}

func pathsArgument(action: String) -> Argument<[String]> {
    return Argument(defaultValue: [""],
                    usage: "list of paths to the files or directories to \(action)")
}

let configOption = Option(key: "config",
                          defaultValue: [String](),
                          usage: "the path to one or more SwiftLint configuration files, "
                            + "evaluated as a parent-child hierarchy")

let useScriptInputFilesOption = Option(key: "use-script-input-files",
                                       defaultValue: false,
                                       usage: "read SCRIPT_INPUT_FILE* environment variables " +
                                            "as files")

let useAlternativeExcludingOption = Option(key: "use-alternative-excluding",
                                           defaultValue: false,
                                           usage: "alternative exclude paths algorithm for `excluded`." +
                                                  "may speed up excluding for some cases")

func quietOption(action: String) -> Option<Bool> {
    return Option(key: "quiet",
                  defaultValue: false,
                  usage: "don't print status logs like '\(action.capitalized) <file>' & " +
                    "'Done \(action)'")
}
