# SwiftLint

SwiftLint는 스위프트 스타일 및 컨벤션을 강제하기 위한 도구로, [Ray Wenderlich 스위프트 스타일 가이드](https://github.com/raywenderlich/swift-style-guide)에 대략적인 기반을 두고 있습니다.

SwiftLint는 좀 더 정확한 결과를 위해 [Clang](http://clang.llvm.org)과 [SourceKit](http://www.jpsim.com/uncovering-sourcekit)에 연결하여 소스 파일의 [AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) 표현을 사용합니다.

[![Build Status](https://dev.azure.com/jpsim/SwiftLint/_apis/build/status/realm.SwiftLint?branchName=main)](https://dev.azure.com/jpsim/SwiftLint/_build/latest?definitionId=4?branchName=main)
[![codecov.io](https://codecov.io/github/realm/SwiftLint/coverage.svg?branch=main)](https://codecov.io/github/realm/SwiftLint?branch=main)

![](assets/screenshot.png)

본 프로젝트는 [Contributor Covenant Code of Conduct](https://realm.io/conduct)를 충실히 따릅니다. 본 프로젝트에 참여함으로써 이러한 수칙을 준수해야 합니다. 받아들일 수 없는 항목이 있다면 [info@realm.io](mailto:info@realm.io)로 알려주세요.

## 설치 방법

### [Homebrew](http://brew.sh/)를 사용하는 경우:

```
brew install swiftlint
```

### [CocoaPods](https://cocoapods.org)를 사용하는 경우:

Podfile에 아래 라인을 추가하기만 하면 됩니다.

```ruby
pod 'SwiftLint'
```

이를 실행하면 다음번 `pod install` 실행 시 SwiftLint 바이너리 및 `Pods/`에 있는 디펜던시들을 다운로드하고, Script Build Phases에서 `${PODS_ROOT}/SwiftLint/swiftlint` 명령을 사용할 수 있게 됩니다.

CocoaPods를 사용하면 최신 버전 외에도 SwiftLint의 특정 버전을 설치할 수 있기 때문에 이 방법을 권장합니다. (Homebrew는 최신 버전만 설치 가능)

이렇게 했을 때 SwiftLint 바이너리 및 그에 종속된 바이너리들과 스위프트 바이너리까지 `Pods/` 디렉터리에 추가되기 때문에, git 등의 SCM에 이런 디렉터리들을 체크인하는 것은 권장하지 않습니다.

### [Mint](https://github.com/yonaskolb/mint)를 사용하는 경우:
```
$ mint install realm/SwiftLint
```

### 빌드된 패키지를 사용하는 경우:

[최신 깃허브 릴리즈](https://github.com/realm/SwiftLint/releases/latest)에서 `SwiftLint.pkg`를 다운로드해서 설치하고 실행할 수 있습니다.

### 소스를 직접 컴파일하는 경우:

본 프로젝트를 클론해서 빌드할 수도 있습니다. `make install` 명령을 사용합니다. (Xcode 12.5 이후 버전)

## 사용 방법

### 프레젠테이션

프로젝트에 SwiftLint를 통합하기 위한 권장 사용 방식의 전반적인 개요를 알고 싶다면, 아래 프레젠테이션 영상을 보거나 스크립트를 읽어보면 좋습니다.

[![Presentation](assets/presentation.svg)](https://academy.realm.io/posts/slug-jp-simard-swiftlint/)

### Xcode

SwiftLint를 Xcode 프로젝트에 통합하여 IDE 상에 경고나 에러를 표시할 수 있습니다. 프로젝트의 파일 내비게이터에서 타겟 앱을 선택 후 "Build Phases" 탭으로 이동합니다. + 버튼을 클릭한 후 "Run Script Phase"를 선택합니다. 그 후 아래 스크립트를 추가하기만 하면 됩니다.

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

![](assets/runscript.png)

만약, 애플 실리콘 환경에서 Homebrew를 통해 SwiftLint를 설치했다면, 아마도 다음과 같은 경고를 겪었을 것입니다.

> warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint

그 이유는, 애플 실리콘 기반 맥에서 Homebrew는 기본적으로 바이너리들을 `/opt/homebrew/bin`에 저장하기 때문입니다. SwiftLint가 어디 있는지 찾는 것을 Xcode에 알려주기 위해, build phase에서 `/opt/homebrew/bin`를 `PATH` 환경 변수에 동시에 추가하여야 합니다.

```bash
export PATH="$PATH:/opt/homebrew/bin"
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

혹은 아래와 같이 `/usr/local/bin`에 심볼릭 링크를 생성하여 실제 바이너리가 있는 곳으로 포인팅할 수 있습니다. :

```bash
ln -s /opt/homebrew/bin/swiftlint /usr/local/bin/swiftlint
```

당신은 SwiftLint phase를 'Compile Sources' 단계 직전으로 옮겨 컴파일 전에 에러를 빠르게 찾고 싶어 할 것입니다. 하지만, SwiftLint는 컴파일러의 구문 분석 단계를 완벽히 수행하는 유효한 Swift 코드를 실행하기 위해 설계되었습니다. 따라서, 'Compile Sources' 전에 SwiftLint를 실행하면 일부 부정확한 오류가 발생할 수도 있습니다.

만약 당신은 위반 사항(violations)을 동시에 수정하는 것을 원한다면, 스크립트에 `swiftlint` 대신 `swiftlint --fix && swiftlint`을 적어야 합니다. 이는 프로젝트의 수정 가능한 모든 위반 사항들이 수정되고 나머지 위반 사항에 대한 경고가 표시된다는 것을 의미합니다.

CocoaPods를 사용해서 설치한 경우는 아래 스크립트를 대신 사용합니다.

```bash
"${PODS_ROOT}/SwiftLint/swiftlint"
```

#### Xcode 저장시 실행되는 플러그인

Xcode에서 저장시 `swiftlint autocorrect`를 실행하려면 Alcatraz에서 [SwiftLintXcode](https://github.com/ypresto/SwiftLintXcode) 플러그인을 설치합니다.

⚠ ️이 플러그인은 Xcode 8에서 SIP를 비활성화하지 않으면 동작하지 않으며, 이는 권장하지 않습니다.

### AppCode

AppCode에서 SwiftLint를 사용하려면 [이 플러그인](https://plugins.jetbrains.com/plugin/9175)을 설치하고 플러그인 환경설정에서 SwiftLint가 설치된 경로를 지정해줍니다. `autocorrect` 액션은 `⌥⏎` 단축키로 사용할 수 있습니다.

### Atom

[Atom](https://atom.io/)에서 SwiftLint를 사용하려면 APM에서 [`linter-swiftlint`](https://atom.io/packages/linter-swiftlint) 패키지를 설치합니다.

### fastlane

fastlane 과정에서 SwiftLint를 사용하려면 [공식적인 fastlane 액션](https://docs.fastlane.tools/actions/swiftlint)를 사용할 수 있습니다.

```ruby
swiftlint(
  mode: :lint,                            # SwiftLint 모드: :lint (디폴트) 아니면 :autocorrect
  executable: "Pods/SwiftLint/swiftlint", # SwiftLint 바이너리 경로 (선택 가능). CocoaPods를 사용해서 설치한 경우는 이 옵션이 중요합니다
  output_file: "swiftlint.result.json",   # 결과 파일의 경로 (선택 가능)
  reporter: "json",                       # 보고 유형 (선택 가능)
  config_file: ".swiftlint-ci.yml",       # 설정 파일의 경로 (선택 가능)
  ignore_exit_status: true                # SwiftLint 종료할 때 0이 아닌 반환한 종료 코드를 무시해서 fastlane 계속 실행합니다
)
```

### 커맨드 라인

```
$ swiftlint help
Available commands:

   autocorrect  Automatically correct warnings and errors
   help         Display general or command-specific help
   lint         Print lint warnings and errors for the Swift files in the current directory (default command)
   rules        Display the list of rules and their identifiers
   version      Display the current version of SwiftLint
```

스위프트 파일이 있는 디렉터리에서 `swiftlint`를 실행합니다. 디렉터리는 재귀적으로 탐색됩니다.

`lint`나 `autocorrect`를 사용할 때 여러 파일(예를 들면, [`ExtraBuildPhase`](https://github.com/norio-nomura/ExtraBuildPhase) 플러그인에 의해 Xcode가 변경한 파일들 혹은 `git ls-files -m` 명령으로 인해 작업 트리에서 변경된 파일들)을 지정하려면 `--use-script-input-files` 옵션을 넘기고 다음 인스턴스 변수들을 설정하면 됩니다. `SCRIPT_INPUT_FILE_COUNT` and
`SCRIPT_INPUT_FILE_0`, `SCRIPT_INPUT_FILE_1`...`SCRIPT_INPUT_FILE_{SCRIPT_INPUT_FILE_COUNT - 1}`

이는 [Xcode의 커스텀 스크립트 단계](http://indiestack.com/2014/12/speeding-up-custom-script-phases/)에 입력 파일로 환경 변수를 지정하는 것과 동일합니다.

### 스위프트 여러 버전에 대한 대응

SwiftLint는 SourceKit에 연결되어 있으므로 스위프트 언어가 변화하더라도 이상 없이 동작할 수 있습니다.

이는 전체 스위프트 컴파일러가 포함되지 않아도 되므로 SwiftLint가 간결하게 유지될 수 있습니다. SwiftLint는 데스크탑에 이미 설치되어 있는 공식 스위프트 컴파일러와 통신하기만 하면 됩니다.

SwiftLint를 실행할 때는 항상 스위프트 파일을 컴파일하는 동일한 툴체인을 사용해야 합니다.

설치된 툴체인이나 Xcode가 여러 개인 경우 혹은 스위프트 구 버전을 사용해야 하는 경우(Xcode 8에서 스위프트 2.3 버전을 사용하는 경우)에는 SwiftLint의 기본 스위프트 툴체인을 변경해야 할 수도 있습니다. 

SwiftLint가 어느 스위프트 툴체인을 사용할지 결정하는 순서는 다음과 같습니다.

* `$XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`
* `$TOOLCHAIN_DIR` or `$TOOLCHAINS`
* `xcrun -find swift`
* `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`

`sourcekitd.framework`은 위에서 선택된 경로의 `usr/lib/` 하위 디렉터리에 존재해야 합니다.

`TOOLCHAINS` 환경 변수에 스위프트 툴체인 버전을 식별할 수 있는 값을 리버스 DNS 형식으로 지정할 수도 있습니다.

```shell
$ TOOLCHAINS=com.apple.dt.toolchain.Swift_2_3 swiftlint autocorrect
```

리눅스에서는 SourceKit이 `/usr/lib/libsourcekitdInProc.so` 혹은 `LINUX_SOURCEKIT_LIB_PATH` 환경변수로 지정된 경로에 존재해야 합니다.

## 룰

SwiftLint에는 200개가 넘는 룰들이 있고, 스위프트 커뮤니티(바로 여러분들!)는 이를 지속적으로 발전시켜 가고 있습니다. [풀 리퀘스트](CONTRIBUTING.md)는 언제나 환영입니다.

현재 구현된 룰 전체를 확인하려면 [Source/SwiftLintFramework/Rules](Source/SwiftLintFramework/Rules)를 살펴보세요.

`opt_in_rules`는 기본적으로 비활성화되어 있습니다. (즉, 설정 파일에서 명시적으로 해당 룰을 활성화해야 합니다.)

다음은 룰을 옵트 인으로 구현하는 경우에 대한 기준입니다.

* 잘못 판단될 가능성이 많은 룰 (예: `empty_count`)
* 속도가 매우 느린 룰
* 일반적으로 모든 사람이 합의하지 않거나 특정한 상황에만 유용한 룰 (예: `force_unwrapping`, `missing_docs`)

### 코드에서 룰 비활성화하기

소스 파일에서 아래 형식의 주석을 사용하면 룰을 비활성화할 수 있습니다.

`// swiftlint:disable <룰1> [<룰2> <룰3>...]`

비활성화된 룰은 해당 파일의 마지막까지 적용되거나, 활성화 주석이 나타날 때까지 적용됩니다.

`// swiftlint:enable <룰1> [<룰2> <룰3>...]`

예를 들면 다음과 같습니다.

```swift
// swiftlint:disable colon
let noWarning :String = "" // 변수명 바로 뒤에 콜론이 위치하지 않는다고 경고가 뜨지 않습니다!
// swiftlint:enable colon
let hasWarning :String = "" // 변수명 바로 뒤에 콜론이 위치해야 한다는 경고가 표시됩니다.
```

`disable`과 `enable` 명령 뒤에 `:previous`, `:this`, `:next`를 붙이면 각각 명령이 위치한 이전 라인, 현재 라인, 다음 라인만 룰이 적용되게 할 수 있습니다.

예를 들면 다음과 같습니다.

```swift
// swiftlint:disable:next force_cast
let noWarning = NSNumber() as! Int
let hasWarning = NSNumber() as! Int
let noWarning2 = NSNumber() as! Int // swiftlint:disable:this force_cast
let noWarning3 = NSNumber() as! Int
// swiftlint:disable:previous force_cast
```

`swiftlint rules`를 실행하면 모든 룰 목록과 룰별 식별자가 표시됩니다.

### 설정

SwiftLint가 실행될 디렉터리에 `.swiftlint.yml` 파일을 추가해서 SwiftLint를 설정할 수 있습니다. 아래 파라미터들을 설정 가능합니다.

룰 적용여부 설정:

* `disabled_rules`: 기본 활성화된 룰 중에 비활성화할 룰들을 지정합니다.
* `opt_in_rules`: 기본 룰이 아닌 룰들을 활성화합니다.
* `only_rules`: 지정한 룰들만 활성화되도록 화이트리스트로 지정합니다. `disabled_rules` 및 `opt_in_rules`과는 같이 사용할 수 없습니다.

```yaml
disabled_rules: # 실행에서 제외할 룰 식별자들
  - colon
  - comma
  - control_statement
opt_in_rules: # 일부 룰은 옵트 인 형태로 제공
  - empty_count
  - missing_docs
  # 사용 가능한 모든 룰은 swiftlint rules 명령으로 확인 가능
included: # 린트 과정에 포함할 파일 경로. 이 항목이 존재하면 `--path`는 무시됨
  - Source
excluded: # 린트 과정에서 무시할 파일 경로. `included`보다 우선순위 높음
  - Carthage
  - Pods
  - Source/ExcludedFolder
  - Source/ExcludedFile.swift

# 설정 가능한 룰은 이 설정 파일에서 커스터마이징 가능
# 경고나 에러 중 하나를 발생시키는 룰은 위반 수준을 설정 가능
force_cast: warning # 암시적으로 지정
force_try:
  severity: warning # 명시적으로 지정
# 경고 및 에러 둘 다 존재하는 룰의 경우 값을 하나만 지정하면 암시적으로 경고 수준에 설정됨
line_length: 110
# 값을 나열해서 암시적으로 양쪽 다 지정할 수 있음
type_body_length:
  - 300 # 경고
  - 400 # 에러
# 둘 다 명시적으로 지정할 수도 있음
file_length:
  warning: 500
  error: 1200
# 네이밍 룰은 경고/에러에 min_length와 max_length를 각각 설정 가능
# 제외할 이름을 설정할 수 있음
type_name:
  min_length: 4 # 경고에만 적용됨
  max_length: # 경고와 에러 둘 다 적용
    warning: 40
    error: 50
  excluded: iPhone # 제외할 문자열 값 사용
identifier_name:
  min_length: # min_length에서
    error: 4 # 에러만 적용
  excluded: # 제외할 문자열 목록 사용
    - id
    - URL
    - GlobalAPIKey
reporter: "xcode" # 보고 유형 (xcode, json, csv, codeclimate, checkstyle, junit, html, emoji, sonarqube, markdown, github-actions-logging)
```

#### 커스텀 룰 정의

아래 문법을 사용하여 설정 파일에 새로운 정규 표현식 기반의 룰을 정의할 수 있습니다.

```yaml
custom_rules:
  pirates_beat_ninjas: # 룰 식별자
    included: ".*.swift" # 린트 실행 시 포함할 경로를 정의하는 정규표현식. 선택 가능.
    name: "Pirates Beat Ninjas" # 룰 이름. 선택 가능.
    regex: "([nN]inja)" # 패턴 매칭
    match_kinds: # 매칭할 SyntaxKinds. 선택 가능.
      - comment
      - identifier
    message: "Pirates are better than ninjas." # 위반 메시지. 선택 가능.
    severity: error # 위반 수준. 선택 가능.
  no_hiding_in_strings:
    regex: "([nN]inja)"
    match_kinds: string
```

결과는 다음과 같습니다.

![](assets/custom-rule.png)

하나 이상의 `match_kinds`를 사용해서 매칭된 결과를 필터링할 수 있습니다. 이 목록에 들어있지 않은 구문 유형이 포함된 결과는 매칭에서 제외됩니다. 사용 가능한 모든 구문 유형은 다음과 같습니다.

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

#### 중첩 구성

SwiftLint는 설정 파일을 중첩되게 구성해서 린트 과정을 더욱 세밀하게 제어할 수 있습니다.

* 디렉터리 구조에서 필요한 곳이면 어디든지 `.swiftlint.yml` 파일을 추가할 수 있습니다.
* 각 파일은 자신의 디렉터리 내에 있는 설정 파일을 사용하거나, 계층구조 상 가장 가까운 부모 디렉터리에 있는 설정 파일을 사용해서 린트됩니다. 별도로 설정 파일이 존재하지 않으면 루트에 있는 설정 파일이 사용됩니다.
* 중첩 구성에서 `excluded` 및 `included`는 무시됩니다.

### 자동 수정

SwiftLint는 일부 위반 사항들을 자동으로 수정할 수 있습니다. 디스크 상의 파일들은 수정된 버전으로 덮어 쓰여지게 됩니다.

`swiftlint autocorrect`를 실행하기 전에 파일들을 백업해주세요. 그렇지 않으면 중요한 데이터가 유실될 수도 있습니다.

표준 린트 검사는 자동 수정 중에는 비활성화됩니다. 위반 사항들은 파일이 자동 수정된 후에 더이상 유효하지 않을 가능성이 크기 때문입니다.

## 라이선스

[MIT 라이선스.](LICENSE)

## About

<img src="assets/realm.png" width="184" />

SwiftLint는 Realm Inc.에 의해 만들어져서 관리되고 있습니다. Realm의 이름과 로고는 Realm Inc.의 트레이드 마크입니다.

우리는 오픈 소스 소프트웨어를 사랑합니다:heart:! Realm의 [다른 오픈소스 프로젝트](https://github.com/realm)와 [블로그](https://realm.io/news)들도 들러주시고, 트위터([@realm](https://twitter.com/realm))로도 반갑게 인사 주세요.
