# SwiftLint

SwiftLint 是一个用于强制检查 Swift 代码风格和规定的一个工具，基本上以 [Kodeco's Swift 代码风格指南](https://github.com/kodecocodes/swift-style-guide)为基础。

SwiftLint Hook 了 [Clang](http://clang.llvm.org) 和 [SourceKit](http://www.jpsim.com/uncovering-sourcekit) 从而能够使用 [AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) 来表示源代码文件的更多精确结果。

[![Build Status](https://dev.azure.com/jpsim/SwiftLint/_apis/build/status/realm.SwiftLint?branchName=main)](https://dev.azure.com/jpsim/SwiftLint/_build/latest?definitionId=4?branchName=main)
[![codecov.io](https://codecov.io/github/realm/SwiftLint/coverage.svg?branch=main)](https://codecov.io/github/realm/SwiftLint?branch=main)

![](assets/screenshot.png)

该项目遵守 [贡献者契约行为守则](https://realm.io/conduct)。一旦参与，你将被视为支持这一守则。请将
不可接受的行为报告给 [info@realm.io](mailto:info@realm.io)。

## 安装
### 使用[Swift Package Manager](https://github.com/apple/swift-package-manager)

SwiftLint 可以用作[命令插件](#swift-package-command-plugin)或[构建工具插件](#build-tool-plugins)

添加

```swift
.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "<version>")
```

到你的 `Package.swift` 文件中，以自动获取 SwiftLint 的最新版本，或者将依赖项固定到特定版本：

```swift
.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "<version>")
```

其中，用所需的最低版本或精确版本替换 `<version>`。


### [Xcode Package Dependency](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

使用以下链接将 SwiftLint 作为包依赖添加到 Xcode 项目中：

```bash
https://github.com/SimplyDanny/SwiftLintPlugins
```


### 使用 [Homebrew](http://brew.sh/)：

```
brew install swiftlint
```

### 使用 [CocoaPods](https://cocoapods.org)：

将如下代码添加到你的 Podfile 即可：

```ruby
pod 'SwiftLint'
```

在下一次执行 `pod install` 时将会把 SwiftLint 的二进制文件和依赖下载到 `Pods/` 目录下并且将允许你通过 `${PODS_ROOT}/SwiftLint/swiftlint` 在 Script Build Phases 中调用 SwiftLint。

自从 SwiftLint 支持安装某个特定版本后，安装一个指定版本的 SwiftLint 是目前推荐的做法相比较于简单地选择最新版本安装的话（比如通过 Homebrew 安装的话）。

请注意这会将 SwiftLint 二进制文件、所依赖的二进制文件和 Swift 二进制库安装到 `Pods/` 目录下，所以不推荐将此目录添加到版本控制系统（如 git）中进行跟踪。

### 使用 [Mint](https://github.com/yonaskolb/mint)：
```
$ mint install realm/SwiftLint
```

### 使用安装包：

你也可以通过从[最新的 GitHub 发布地址](https://github.com/realm/SwiftLint/releases/latest)下载 `SwiftLint.pkg` 然后执行的方式安装 SwiftLint。

### 编译源代码：

你也可以通过 clone SwiftLint 的 Git 仓库到本地然后执行
`make install` (Xcode 15.0+) 以从源代码构建及安装。

### 使用 Bazel

把这个放到你的 `MODULE.bazel`：

```bzl
bazel_dep(name = "swiftlint", version = "0.50.4", repo_name = "SwiftLint")
```

或把它放到你的 `WORKSPACE`：

<details>

<summary>WORKSPACE</summary>

```bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "390841dd5f8a85fc25776684f4793d56e21b098dfd7243cd145b9831e6ef8be6",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.4.1/rules_apple.2.4.1.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

http_archive(
    name = "SwiftLint",
    sha256 = "c6ea58b9c72082cdc1ada4a2d48273ecc355896ed72204cedcc586b6ccb8aca6",
    url = "https://github.com/realm/SwiftLint/releases/download/0.52.4/bazel.tar.gz",
)

load("@SwiftLint//bazel:repos.bzl", "swiftlint_repos")

swiftlint_repos()

load("@SwiftLint//bazel:deps.bzl", "swiftlint_deps")

swiftlint_deps()
```

</details>

然后你就可以在当前目录下使用这个命令运行 SwiftLint：

```console
bazel run -c opt @SwiftLint//:swiftlint
```


## 用法

### 报告

我们鼓励你观看本次报告，来获得将 SwiftLint 整合到你的项目中的推荐方式的一个高层次概括：

[![Presentation](assets/presentation.svg)](https://youtu.be/9Z1nTMTejqU)

### Xcode

整合 SwiftLint 到 Xcode 体系中去从而可以使警告和错误显示到 IDE 上，只需要在 Xcode 中添加一个新的“Run Script Phase”并且包含如下代码即可：

![](https://raw.githubusercontent.com/realm/SwiftLint/main/assets/runscript.png)

Xcode 15 对 Build Settings 进行了重大更改，它将 `ENABLE_USER_SCRIPT_SANDBOXING` 的默认值从 `NO` 更改为 `YES`。
因此，SwiftLint 会遇到与缺少文件权限相关的错误，通常报错信息为：`error: Sandbox: swiftlint(19427) deny(1) file-read-data.`

要解决此问题，需要手动将 `ENABLE_USER_SCRIPT_SANDBOXING` 设置为 `NO`，以针对 SwiftLint 配置的特定目标。

如果你是在搭载 Apple 芯片的 Mac 上通过 Homebrew 安装的 SwiftLint，你可能会遇到这个警告：

> warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint

这是因为 Homebrew 在搭载 Apple 芯片的 Mac 上将二进制文件默认安装到了 `/opt/homebrew/bin`
下。如果要让 Xcode 知道 SwiftLint 在哪，你可以在 Build Phase 中将
`/opt/homebrew/bin` 路径添加到 `PATH` 环境变量

```bash
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

或者，你可以创建一个指向在 `/usr/local/bin` 中实际二进制文件的符号链接：

```bash
ln -s /opt/homebrew/bin/swiftlint /usr/local/bin/swiftlint
```

你可能希望将SwiftLint阶段直接移到'Compile Sources'
步骤之前，以便在编译之前快速检测错误。但是，SwiftLint 被设计
为在有效的 Swift 代码上运行，这些代码干净利落地完成了编译器的解析阶段。
因此，在'Compile Sources'之前运行 SwiftLint 可能会产生一些不正确的结果。

如果你也希望修正违规行为，你的脚本可以运行
`swiftlint --fix && swiftlint` 而不是 `swiftlint`。 这将意味着
修复所有可纠正的违规行为，同时确保在你的项目中对剩余的违规行为显示警告。

如果你已经通过 CocoaPods 安装了 SwiftLint，脚本看起来应该像这样：

```bash
"${PODS_ROOT}/SwiftLint/swiftlint"
```

### 插件支持

SwiftLint 既可以作为 Xcode 项目构建工具，也可以作为 Swift package。

> 由于 Swift Package Manager 插件的限制，仅推荐
> 在其根目录中有 SwiftLint 配置的项目使用，因为
目前没有办法将任何附加选项传递给 SwiftLint 可执行文件。

#### Xcode

如果你正在使用 Xcode 中的项目，你可以将 SwiftLint 集成为
Xcode 构建工具插件。

将 SwiftLint 作为依赖包添加到你的项目中，无需链接任何其他服务。

选择要添加修正的目标，打开 `Build Phases` 检查器。
打开 `Run Build Tool Plug-ins` 并选择 `+` 按钮。
从列表中选择 `SwiftLintBuildToolPlugin` 并将其添加到项目中。

![](https://raw.githubusercontent.com/realm/SwiftLint/main/assets/select-swiftlint-plugin.png)

对于无人值守的使用场景（例如在 CI 上），可以通过以下方式禁用软件包和宏的验证对话框

* 单独将 `-skipPackagePluginValidation` 和 `-skipMacroValidation` 传递到 `xcodebuild` 或者
* 为那个用户使用 `defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES` 进行全局设置，然后写入 `defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES` 

_注意：这将隐含地信任所有的Xcode软件包插件，并绕过Xcode的软件包验证对话框。
       这对安全有影响。_

#### Swift Package

你可以将 SwiftLint 集成为 Swift Package Manager 插件，如果你正在使用
具有 `Package.swift` 清单的 Swift 包。

将 SwiftLint 作为包依赖添加到你的 `Package.swift` 文件中。  
使用`plugins`参数将SwiftLint添加到目标。

```swift
.target(
    ...
    plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
),
```

### Visual Studio Code

如果要在[vscode](https://code.visualstudio.com)上使用 SwiftLint，在应用市场上安装
[`vscode-swiftlint`](https://marketplace.visualstudio.com/items?itemName=vknabel.vscode-swiftlint)扩展。

### fastlane

你可以用[fastlane官方的SwiftLint功能](https://docs.fastlane.tools/actions/swiftlint)来运行 SwiftLint 作为你的 Fastlane 程序的一部分。

```ruby
swiftlint(
    mode: :lint,                            # SwiftLint模式: :lint (默认) 或者 :autocorrect
    executable: "Pods/SwiftLint/swiftlint", # SwiftLint的程序路径 (可选的). 对于用CocoaPods集成SwiftLint时很重要
    path: "/path/to/lint",                  # 特殊的检查路径 (可选的)
    output_file: "swiftlint.result.json",   # 检查结果输出路径 (可选的)
    reporter: "json",                       # 输出格式 (可选的)
    config_file: ".swiftlint-ci.yml",       # 配置文件的路径 (可选的)
    files: [                                # 指定检查文件列表 (可选的)
        "AppDelegate.swift",
        "path/to/project/Model.swift"
    ],
    ignore_exit_status: true,               # 允许fastlane可以继续执行甚至是Swiftlint返回一个非0的退出状态(默认值: false)
    quiet: true,                            # 不输出像‘Linting’和‘Done Linting’的状态日志 (默认值: false)
    strict: true                            # 发现警告时报错? (默认值: false)
)
```

### Docker

`swiftlint` 也可以在 [Docker](https://www.docker.com/) 上使用 `Ubuntu` 作为一个镜像使用。
因此，第一次你需要使用下面的命令调用 docker 镜像：
```bash
docker pull ghcr.io/realm/swiftlint:latest
```

接下来，你只需在 docker 中运行`swiftlint`：
```bash
docker run -it -v `pwd`:`pwd` -w `pwd` ghcr.io/realm/swiftlint:latest
```

这将在你现在所在的文件夹（`pwd`）中执行`swiftlint`，显示类似的输出：
```bash
$ docker run -it -v `pwd`:`pwd` -w `pwd` ghcr.io/realm/swiftlint:latest
Linting Swift files in current working directory
Linting 'RuleDocumentation.swift' (1/490)
...
Linting 'YamlSwiftLintTests.swift' (490/490)
Done linting! Found 0 violations, 0 serious in 490 files.
```

这里有更多关于使用[Docker 镜像](https://docs.docker.com/)的文档。

### 命令行

```
$ swiftlint help
Available commands:

   autocorrect  Automatically correct warnings and errors
   help         Display general or command-specific help
   lint         Print lint warnings and errors for the Swift files in the current directory (default command)
   rules        Display the list of rules and their identifiers
   version      Display the current version of SwiftLint
```

在包含有需要执行代码分析的 Swift 源码文件的目录下执行 `swiftlint` 命令，会对目录进行递归查找。

当使用 `lint` 或者 `autocorrect` 命令时，你可以通过添加 `--use-script-input-files` 选项并且设置以下实例变量：`SCRIPT_INPUT_FILE_COUNT` 和
`SCRIPT_INPUT_FILE_0`, `SCRIPT_INPUT_FILE_1`... `SCRIPT_INPUT_FILE_{SCRIPT_INPUT_FILE_COUNT - 1}` 的方式来指定一个文件列表（就像被 Xcode 特别是 [`ExtraBuildPhase`](https://github.com/norio-nomura/ExtraBuildPhase) Xcode 插件修改的文件组成的列表，或者类似 Git 工作树中 `git ls-files -m` 命令显示的被修改的文件列表）。

也有类似的用来设置输入文件的环境变量以 [自定义 Xcode script phases](http://indiestack.com/2014/12/speeding-up-custom-script-phases/) 。

### 使用多个 Swift 版本

SwiftLint 工作于 SourceKit 这一层，所以 Swift 版本发生变化时它也能继续工作！

这也是 SwiftLint 轻量化的原因，因为它不需要一个完整的 Swift 编译器，它只是与已经安装在你的电脑上的官方编译器进行通信。

你应该总是使用和你编译代码同样的工具集来执行 SwiftLint。

如果你有多套工具集或者安装了多个不同版本的 Xcode，你可能会需要覆盖 SwiftLint 默认的工具集。

下面这些命令可以控制 SwiftLint 使用哪一个 Swift 工具集来进行工作：

* `$XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`
* `$TOOLCHAIN_DIR` 或者 `$TOOLCHAINS`
* `xcrun -find swift`
* `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`

`sourcekitd.framework` 默认需要位于 `usr/lib/` 中，上面传入的路径的子目录中。

你可能也给反向 DNS 符号设置了 `TOOLCHAINS` 环境变量来标记一个特定的 Swift 工具集版本：

```shell
$ TOOLCHAINS=com.apple.dt.toolchain.Swift_2_3 swiftlint autocorrect
```

在 Linux 上，SourceKit 默认需要位于 `/usr/lib/libsourcekitdInProc.so` 或者通过 `LINUX_SOURCEKIT_LIB_PATH` 环境变量进行指定。

### 预提交

SwiftLint 可以作为一个 [预提交](https://pre-commit.com/) 钩子运行。
一当 [安装](https://pre-commit.com/#install)，把这个添加到在 root 路径中的
`.pre-commit-config.yaml` 里：

```yaml
repos:
  - repo: https://github.com/realm/SwiftLint
    rev: 0.50.3
    hooks:
      - id: swiftlint
```

将 `rev` 调整为您选择的 SwiftLint 版本。可以使用 `pre-commit autoupdate` 来更新到当前版本。

SwiftLint 可以使用 `entry` 进行配置以应用修复和报错：
```yaml
-   repo: https://github.com/realm/SwiftLint
    rev: 0.50.3
    hooks:
    -   id: swiftlint
        entry: swiftlint --fix --strict
```

## 规则

SwiftLint 已经包含了超过 200 条规则，并且我们希望 Swift 社区（就是你！）会在以后有更多的贡献，我们鼓励提交 [Pull Requests](CONTRIBUTING.md)。

你可以在 [这里](https://realm.github.io/SwiftLint/rule-directory.html) 找到规则的更新列表和更多信息。

你也可以查看 [Source/SwiftLintBuiltInRules/Rules](Source/SwiftLintBuiltInRules/Rules) 目录来查看它们的实现。

### Opt-In 规则

`opt_in_rules` 默认是关闭的（即，你需要在你的配置文件中明确地打开它们）。

什么时候需要将一个规则设为 opt-in 的指南：

* 一个可能会有许多负面作用的规则（例如 `empty_count`）
* 一个过慢的规则
* 一个不通用或者仅在某些特定场景下可用的规则（例如 `force_unwrapping`）

### 在代码中关闭某个规则

可以通过在一个源文件中定义一个如下格式的注释来关闭某个规则：

`// swiftlint:disable <rule1> [<rule2> <rule3>...]`

在该文件结束之前或者在定义如下格式的匹配注释之前，这条规则都会被禁用：

`// swiftlint:enable <rule1> [<rule2> <rule3>...]`

例如：

```swift
// swiftlint:disable colon
let noWarning :String = "" // No warning about colons immediately after variable names!
// swiftlint:enable colon
let hasWarning :String = "" // Warning generated about colons immediately after variable names
```

包含 "all "关键字将禁用所有的规则，直到 linter 看到匹配的启用注释：

`// swiftlint:disable all`
`// swiftlint:enable all`

例如：

```swift
// swiftlint:disable all
let noWarning :String = "" // No warning about colons immediately after variable names!
let i = "" // Also no warning about short identifier names
// swiftlint:enable all
let hasWarning :String = "" // Warning generated about colons immediately after variable names
let y = "" // Warning generated about short identifier names
```

也可以通过添加`:previous`、`:this`或`:next`来修改`disable`或`enable`命令，
使它们只对前一行，当前或者后一行代码有效。

例如：

```swift
// swiftlint:disable:next force_cast
let noWarning = NSNumber() as! Int
let hasWarning = NSNumber() as! Int
let noWarning2 = NSNumber() as! Int // swiftlint:disable:this force_cast
let noWarning3 = NSNumber() as! Int
// swiftlint:disable:previous force_cast
```

执行 `swiftlint rules` 命令可以输出所有可用的规则和他们的标识符组成的列表。

### 配置

可以通过在你需要执行 SwiftLint 的目录下添加一个 `.swiftlint.yml` 文件的方式来配置 SwiftLint。可以被配置的参数有：

包含的规则：

* `disabled_rules`: 关闭某些默认开启的规则。
* `opt_in_rules`: 一些规则是可选的。
* `only_rules`: 不可以和 `disabled_rules` 或者 `opt_in_rules` 并列。类似一个白名单，只有在这个列表中的规则才是开启的。

```yaml
disabled_rules: # 执行时排除掉的规则
  - colon
  - comma
  - control_statement
opt_in_rules: # 一些规则是默认关闭的，所以你需要手动启用
  - empty_count # 你可以通过执行如下指令来查找所有可用的规则：`swiftlint rules`
# 或者，通过取消对该选项的注释来明确指定所有规则：
# only_rules：# 如果使用，请删除 `disabled_rules` 或 `opt_in_rules`
#   - empty_parameters
#   - vertical_whitespace

analyzer_rules: # `swiftlint analyze` 运行的规则
  - explicit_self

included: # 执行 linting 时包含的路径。如果出现这个 `--path` 会被忽略。
  - Sources
excluded: # 执行 linting 时忽略的路径。 优先级比 `included` 更高。
  - Carthage
  - Pods
  - Sources/ExcludedFolder
  - Sources/ExcludedFile.swift

# 如果值为 true，SwiftLint 将把所有警告都视为错误
strict: false

# 可配置的规则可以通过这个配置文件来自定义
# 二进制规则可以设置他们的严格程度
force_cast: warning # 隐式
force_try:
  severity: warning # 显式
# 同时有警告和错误等级的规则，可以只设置它的警告等级
# 隐式
line_length: 110
# 可以通过一个数组同时进行隐式设置
type_body_length:
  - 300 # warning
  - 400 # error
# 或者也可以同时进行显式设置
file_length:
  warning: 500
  error: 1200
# 命名规则可以设置最小长度和最大程度的警告/错误
# 此外它们也可以设置排除在外的名字
type_name:
  min_length: 4 # 只是警告
  max_length: # 警告和错误
    warning: 40
    error: 50
  excluded: iPhone # 排除某个名字
identifier_name:
  min_length: # 只有最小长度
    error: 4 # 只有错误
  excluded: # 排除某些名字
    - id
    - URL
    - GlobalAPIKey
reporter: "xcode" # 报告类型 (xcode, json, csv, checkstyle, codeclimate, junit, html, emoji, sonarqube, markdown, github-actions-logging)
```

#### 定义自定义规则

你可以用如下语法在你的配置文件里定义基于正则表达式的自定义规则：

```yaml
custom_rules:
  pirates_beat_ninjas: # 规则标识符
    name: "Pirates Beat Ninjas" # 规则名称，可选
    regex: "([nN]inja)" # 匹配的模式
    match_kinds: # 需要匹配的语法类型，可选
      - comment
      - identifier
    message: "Pirates are better than ninjas." # 提示信息，可选
    severity: error # 提示的级别，可选
  no_hiding_in_strings:
    regex: "([nN]inja)"
    match_kinds: string
```

输出大概可能是这个样子的：

![](assets/custom-rule.png)

你可以通过提供一个或者多个 `match_kinds` 的方式来对匹配进行筛选，它会将含有不包括在列表中的语法类型的匹配排除掉。这里有全部可用的语法类型：

* argument
* attribute.builtin
* attribute.id
* buildconfig.id
* buildconfig.keyword
* comment
* comment.mark
* comment.url
* doccomment
* doccomment.field
* identifier
* keyword
* number
* objectliteral
* parameter
* placeholder
* string
* string_interpolation_anchor
* typeidentifier

#### 嵌套配置

SwiftLint 支持通过嵌套配置文件的方式来对代码分析过程进行更加细致的控制。

* 在你需要的目录引入 `.swiftlint.yml`。
* 在目录结构必要的地方引入额外的 `.swiftlint.yml` 文件。
* 每个文件被检查时会使用在文件所在目录下的或者父目录的更深层目录下的配置文件。否则根配置文件将会生效。
* `excluded` 和 `included` 在嵌套结构中会被忽略。

### 自动更正

SwiftLint 可以自动修正某些错误，磁盘上的文件会被一个修正后的版本覆盖。

请确保在对文件执行 `swiftlint autocorrect` 之前有对它们做过备份，否则的话有可能导致重要数据的丢失。

因为在执行自动更正修改某个文件后很有可能导致之前生成的代码检查信息无效或者不正确，所以当在执行代码更正时标准的检查是无法使用的。

## 协议

[MIT 许可。](LICENSE)

## 关于

<img src="assets/realm.png" width="184" />

SwiftLint 是由 Realm Inc 建立和维护的。Realm 的名字和标志是属于 Realm Inc 的注册商标。

我们 :heart: 开源软件！看一下[我们的其他开源项目](https://github.com/realm)，瞅一眼[我们的博客](https://realm.io/news)，或者在推特上跟我们唠唠嗑([@realm](https://twitter.com/realm))。

<img src="https://raw.githubusercontent.com/realm/SwiftLint/main/assets/macstadium.png" width="184" />

感谢 MacStadium 为我们的性能测试提供了一台 Mac Mini。
