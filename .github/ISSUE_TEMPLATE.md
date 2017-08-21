### New Issue Checklist

- [ ] Updated SwiftLint to the latest version
- [ ] I searched for [existing GitHub issues](https://github.com/realm/SwiftLint/issues)

### Rule Request

If this is a bug report, please ignore this section.

If this is a new rule request, please ignore all sections below this one, format
this issue's title as `Rule Request: [Rule Name]` and describe:

1. Why should this rule be added? Share links to existing discussion about what
   the community thinks about this.
2. Provide several examples of what _would_ and _wouldn't_ trigger violations.
3. Should the rule be configurable, if so what parameters should be configurable?
4. Should the rule be opt-in or enabled by default? Why?
   See [README.md](../README.md#opt-in-rules) for guidelines on when to mark a
   rule as opt-in.

### Bug Report

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
* Which Xcode version are you using (check `xcode-select -p`)?
* Do you have a sample that shows the issue? Run `echo "[string here]" | swiftlint lint --no-cache --use-stdin --enable-all-rules`
  to quickly test if your example is really demonstrating the issue. If your example is more
  complex, you can use `swiftlint lint --path [file here] --no-cache --enable-all-rules`.

```swift
// This triggers a violation:
let foo = try! bar()
```
