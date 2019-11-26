---
name: Bug report
about: Create a report to help us improve

---

### New Issue Checklist

- [ ] Updated SwiftLint to the latest version
- [ ] I searched for [existing GitHub issues](https://github.com/realm/SwiftLint/issues)

### Describe the bug

A clear and concise description of what the bug is.

##### Complete output when running SwiftLint, including the stack trace and command used

```bash
$ swiftlint lint
```

### Environment

* SwiftLint version (run `swiftlint version` to be sure)?
* Installation method used (Homebrew, CocoaPods, building from source, etc)?
* Paste your configuration file:

```yml
# insert yaml contents here
```

* Are you using [nested configurations](https://github.com/realm/SwiftLint#nested-configurations)?
  If so, paste their relative paths and respective contents.
* Which Xcode version are you using (check `xcodebuild -version`)?
* Do you have a sample that shows the issue? Run `echo "[string here]" | swiftlint lint --no-cache --use-stdin --enable-all-rules`
  to quickly test if your example is really demonstrating the issue. If your example is more
  complex, you can use `swiftlint lint --path [file here] --no-cache --enable-all-rules`.

```swift
// This triggers a violation:
let foo = try! bar()
```
