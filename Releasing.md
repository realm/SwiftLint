# Releasing SwiftLint

For SwiftLint contributors, follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
2. Push new version: `make push_version "0.2.0: Tumble Dry"`
3. Make sure you have the latest stable Xcode version installed and
  `xcode-select`ed.
4. Create the pkg installer, framework zip, and portable zip: `make release`
5. Create a GitHub release: https://github.com/realm/SwiftLint/releases/new
    * Specify the tag you just pushed from the dropdown.
    * Set the release title to the new version number & release name.
    * Add the changelog section to the release description text box.
    * Upload the pkg installer, framework zip, and portable zip you just built
      to the GitHub release binaries.
    * Click "Publish release".
6. Publish to Homebrew and CocoaPods trunk: `make publish`
7. Celebrate. :tada:

## Releasing a Fork

If you need to test your changes with your project before opening a pull request,
you'll need to follow a slightly different set of steps. SwiftLint distributes a
binary through CocoaPods rather than the whole repo, which is what makes this
tricky.

1. Come up with a release name.
1. Set `s.version` in `SwiftLint.podspec` to the version number you'd like to use
   instead of `` `make get_version` ``.
1. Set `s.homepage` in `SwiftLint.podspec` to point to your fork, e.g.
   `'https://github.com/{username}/SwiftLint'`.
1. Commit these changes.
1. Push new version: `make push_version "0.2.0: My Release"`
1. `git push` these changes.
1. Make sure you have the latest stable Xcode version installed and
   `xcode-select`ed.
1. Create the pkg installer, framework zip, portable zip, and Linux zip:
   `make release`
1. Create a GitHub release: https://github.com/{username}/SwiftLint/releases/new
    * Select the tag you just pushed from the dropdown.
    * Set the release title to the new version number & release name.
    * Add a description to the release description text box.
    * Upload the pkg installer, framework zip, portable zip, and Linux zip you
      just built to the GitHub release binaries.
    * Click "Publish release".
 1. In the Podfile of your project, instead of depending on a specific version of
    SwiftLint, point to the raw podspec file:
    `pod 'SwiftLint', podspec: 'https://raw.githubusercontent.com/{username}/SwiftLint/{branch-name}/SwiftLint.podspec'`
 1. Run `pod update SwiftLint` in your project.
