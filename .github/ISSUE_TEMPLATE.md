### New Issue Checklist

- [ ] Updated SwiftLint to the latest version
- [ ] I searched for [existing GitHub issues](https://github.com/realm/SwiftLint/issues)

### Issue Description

(If this is a new rule request, please ignore everything below.)

##### Complete output when running SwiftLint, including the stack trace and command used

```
$ swiftlint lint
```

### Environment

* SwiftLint version (run `swiftlint version` to be sure)?
* Installation method used (Homebrew, CocoaPods, building the source, etc)?
* Paste your configuration file:

```yml
included:
  - you should change this
```

* Are you using [nested configurations](https://github.com/realm/SwiftLint#nested-configurations)?
* Which Xcode version are you using (check `xcode-select -p`)?
* Do you have a sample example that shows the issue? You can run `echo "[string here]" | swiftlint lint --no-cache --use-stdin --enable-all-rules` to quickly test if your example is really demonstrating the issue. 
If your example is a more complex one, you can use `swiftlint lint --path [file here] --no-cache --enable-all-rules`.

```swift
// This triggers a violation:
let foo = try! bar()
```
