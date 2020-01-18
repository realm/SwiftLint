import SwiftLintFramework

extension Example {
    var addingEmoji: Example {
        return with(code: "/* 👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦 */\n\(code)")
    }

    var addingShebang: Example {
        return with(code: "#!/usr/bin/env swift\n\(code)")
    }
}
