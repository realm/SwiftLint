---
name: Bug Report
about: Create a report to help us improve.

---

### New Issue Checklist

- [ ] I've Updated SwiftLint to the latest version.
- [ ] I've searched for [existing GitHub issues](https://github.com/realm/SwiftLint/issues).

### Bug Description

A clear and concise description of what the bug is. Ideally, provide a small (but compilable) example code snippet that
can be used to reproduce the issue.

```swift
// This triggers a violation:
let foo = try! bar()
```

Mention the command or other SwiftLint integration method that caused the issue. Include stack traces or command output.

```bash
$ swiftlint lint [--no-cache] [--fix]
```

### Environment

* SwiftLint version (run `swiftlint version` to be sure)
* Xcode version (run `xcodebuild -version` to be sure)
* Installation method used (Homebrew, CocoaPods, building from source, etc)
* Configuration file:

```yml
# insert yaml contents here
```

Are you using [nested configurations](https://github.com/realm/SwiftLint#nested-configurations)? If so, paste their
relative paths and respective contents.
