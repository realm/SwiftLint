import Dispatch
import Foundation

DispatchQueue.global().async {
    SwiftLint.mainHandlingDeprecatedCommands()
    exit(EXIT_SUCCESS)
}

dispatchMain()
