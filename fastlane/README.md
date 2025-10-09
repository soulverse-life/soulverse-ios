fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios development

```sh
[bundle exec] fastlane ios development
```

Push a dev build to Testflight

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a release build to Testflight

### ios test_upload

```sh
[bundle exec] fastlane ios test_upload
```

Test upload existing IPA to TestFlight

### ios test_match

```sh
[bundle exec] fastlane ios test_match
```

Test Match provisioning profile download

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
