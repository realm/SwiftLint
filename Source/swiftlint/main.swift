import Dispatch

DispatchQueue.global().async {
    SwiftLint.mainHandlingDeprecatedCommands()
    exit(EXIT_SUCCESS)
}

dispatchMain()
