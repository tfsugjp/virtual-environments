| Announcements |
|-|
| [[Macos 13 and 14] Android NDK versions <=25 will be removed from images on October 07,2024](https://github.com/actions/runner-images/issues/10614) |
| [[Macos 13 and 14] Go version 1.20.0 will be removed on October 07,2024.](https://github.com/actions/runner-images/issues/10612) |
| [[macOS] Xcodes visionOS platform will be removed from macOS-14 images on September 23, 2024](https://github.com/actions/runner-images/issues/10559) |
***
# macOS 14
- OS Version: macOS 14.6.1 (23G93)
- Kernel Version: Darwin 23.6.0
- Image Version: 20240918.8

## Installed Software

### Language and Runtime
- .NET Core SDK: 7.0.102, 7.0.202, 7.0.306, 7.0.410, 8.0.101, 8.0.204, 8.0.303, 8.0.401
- Bash 3.2.57(1)-release
- Clang/LLVM 14.0.3
- Clang/LLVM (Homebrew) 15.0.7 - available on `$(brew --prefix llvm@15)/bin/clang`
- GCC 12 (Homebrew GCC 12.4.0) - available by `gcc-12` alias
- GCC 13 (Homebrew GCC 13.3.0) - available by `gcc-13` alias
- GCC 14 (Homebrew GCC 14.2.0) - available by `gcc-14` alias
- GNU Fortran 12 (Homebrew GCC 12.4.0) - available by `gfortran-12` alias
- GNU Fortran 13 (Homebrew GCC 13.3.0) - available by `gfortran-13` alias
- GNU Fortran 14 (Homebrew GCC 14.2.0) - available by `gfortran-14` alias
- Kotlin 2.0.20-release-360
- Mono 6.12.0.188
- Node.js 20.17.0
- Perl 5.38.2
- Python3 3.12.6
- Ruby 3.0.7p220

### Package Management
- Bundler 2.5.19
- Carthage 0.40.0
- CocoaPods 1.15.2
- Homebrew 4.3.23
- NPM 10.8.2
- NuGet 6.3.1.1
- Pip3 24.2 (python 3.12)
- Pipx 1.7.1
- RubyGems 3.5.19
- Yarn 1.22.22

### Project Management
- Apache Ant 1.10.15
- Apache Maven 3.9.9
- Gradle 8.10.1

### Utilities
- 7-Zip 17.05
- aria2 1.37.0
- azcopy 10.26.0
- bazel 7.3.1
- bazelisk 1.21.0
- bsdtar 3.5.3 - available by 'tar' alias
- Curl 8.7.1
- Git 2.46.1
- Git LFS 3.5.1
- GitHub CLI 2.57.0
- GNU Tar 1.35 - available by 'gtar' alias
- GNU Wget 1.24.5
- gpg (GnuPG) 2.4.5
- jq 1.7.1
- OpenSSL 1.1.1w  11 Sep 2023
- Packer 1.9.4
- pkg-config 0.29.2
- yq 4.44.3
- zstd 1.5.6

### Tools
- AWS CLI 2.17.54
- AWS SAM CLI 1.124.0
- AWS Session Manager CLI 1.2.650.0
- Azure CLI 2.64.0
- Azure CLI (azure-devops) 1.0.1
- Bicep CLI 0.30.3
- Cmake 3.30.3
- CodeQL Action Bundle 2.18.4
- Fastlane 2.222.0
- SwiftFormat 0.54.5
- Xcbeautify 2.11.0
- Xcode Command Line Tools 16.0.0.0.1.1724870825
- Xcodes 1.5.0

### Linters

### Browsers
- Safari 17.6 (19618.3.11.11.5)
- SafariDriver 17.6 (19618.3.11.11.5)
- Google Chrome 129.0.6668.59
- Google Chrome for Testing 129.0.6668.58
- ChromeDriver 129.0.6668.58
- Selenium server 4.24.0

#### Environment variables
| Name            | Value                                   |
| --------------- | --------------------------------------- |
| CHROMEWEBDRIVER | /usr/local/share/chromedriver-mac-arm64 |
| EDGEWEBDRIVER   |                                         |
| GECKOWEBDRIVER  |                                         |

### Java
| Version              | Environment Variable |
| -------------------- | -------------------- |
| 11.0.24+8            | JAVA_HOME_11_arm64   |
| 17.0.12+7            | JAVA_HOME_17_arm64   |
| 21.0.4+7.0 (default) | JAVA_HOME_21_arm64   |

### Cached Tools

#### Python
- 3.9.13
- 3.10.11
- 3.11.9
- 3.12.6

#### Node.js
- 18.20.4
- 20.17.0

#### Go
- 1.20.14
- 1.21.13
- 1.22.7
- 1.23.1

### Rust Tools
- Cargo 1.81.0
- Rust 1.81.0
- Rustdoc 1.81.0
- Rustup 1.27.1

#### Packages
- Clippy 0.1.81
- Rustfmt 1.7.1-stable

### PowerShell Tools
- PowerShell 7.4.5

#### PowerShell Modules
- Az: 12.3.0
- Pester: 5.6.1
- PSScriptAnalyzer: 1.22.0

### Xcode
| Version        | Build    | Path                                |
| -------------- | -------- | ----------------------------------- |
| 16.1 (beta)    | 16B5014f | /Applications/Xcode_16.1_beta_2.app |
| 16.0           | 16A242d  | /Applications/Xcode_16.app          |
| 15.4 (default) | 15F31d   | /Applications/Xcode_15.4.app        |
| 15.3           | 15E204a  | /Applications/Xcode_15.3.app        |
| 15.2           | 15C500b  | /Applications/Xcode_15.2.app        |
| 15.1           | 15C65    | /Applications/Xcode_15.1.app        |
| 15.0.1         | 15A507   | /Applications/Xcode_15.0.1.app      |
| 14.3.1         | 14E300c  | /Applications/Xcode_14.3.1.app      |

#### Installed SDKs
| SDK                                                     | SDK Name                                      | Xcode Version |
| ------------------------------------------------------- | --------------------------------------------- | ------------- |
| macOS 13.3                                              | macosx13.3                                    | 14.3.1        |
| macOS 14.0                                              | macosx14.0                                    | 15.0.1        |
| macOS 14.2                                              | macosx14.2                                    | 15.1, 15.2    |
| macOS 14.4                                              | macosx14.4                                    | 15.3          |
| macOS 14.5                                              | macosx14.5                                    | 15.4          |
| macOS 15.0                                              | macosx15.0                                    | 16.0          |
| macOS 15.1                                              | macosx15.1                                    | 16.1          |
| iOS 16.4                                                | iphoneos16.4                                  | 14.3.1        |
| iOS 17.0                                                | iphoneos17.0                                  | 15.0.1        |
| iOS 17.2                                                | iphoneos17.2                                  | 15.1, 15.2    |
| iOS 17.4                                                | iphoneos17.4                                  | 15.3          |
| iOS 17.5                                                | iphoneos17.5                                  | 15.4          |
| iOS 18.0                                                | iphoneos18.0                                  | 16.0          |
| iOS 18.1                                                | iphoneos18.1                                  | 16.1          |
| Simulator - iOS 16.4                                    | iphonesimulator16.4                           | 14.3.1        |
| Simulator - iOS 17.0                                    | iphonesimulator17.0                           | 15.0.1        |
| Simulator - iOS 17.2                                    | iphonesimulator17.2                           | 15.1, 15.2    |
| Simulator - iOS 17.4                                    | iphonesimulator17.4                           | 15.3          |
| Simulator - iOS 17.5                                    | iphonesimulator17.5                           | 15.4          |
| Simulator - iOS 18.0                                    | iphonesimulator18.0                           | 16.0          |
| Simulator - iOS 18.1                                    | iphonesimulator18.1                           | 16.1          |
| tvOS 16.4                                               | appletvos16.4                                 | 14.3.1        |
| tvOS 17.0                                               | appletvos17.0                                 | 15.0.1        |
| tvOS 17.2                                               | appletvos17.2                                 | 15.1, 15.2    |
| tvOS 17.4                                               | appletvos17.4                                 | 15.3          |
| tvOS 17.5                                               | appletvos17.5                                 | 15.4          |
| tvOS 18.0                                               | appletvos18.0                                 | 16.0          |
| tvOS 18.1                                               | appletvos18.1                                 | 16.1          |
| Simulator - tvOS 16.4                                   | appletvsimulator16.4                          | 14.3.1        |
| Simulator - tvOS 17.0                                   | appletvsimulator17.0                          | 15.0.1        |
| Simulator - tvOS 17.2                                   | appletvsimulator17.2                          | 15.1, 15.2    |
| Simulator - tvOS 17.4                                   | appletvsimulator17.4                          | 15.3          |
| Simulator - tvOS 17.5                                   | appletvsimulator17.5                          | 15.4          |
| Simulator - tvOS 18.0                                   | appletvsimulator18.0                          | 16.0          |
| Simulator - tvOS 18.1                                   | appletvsimulator18.1                          | 16.1          |
| watchOS 9.4                                             | watchos9.4                                    | 14.3.1        |
| watchOS 10.0                                            | watchos10.0                                   | 15.0.1        |
| watchOS 10.2                                            | watchos10.2                                   | 15.1, 15.2    |
| watchOS 10.4                                            | watchos10.4                                   | 15.3          |
| watchOS 10.5                                            | watchos10.5                                   | 15.4          |
| watchOS 11.0                                            | watchos11.0                                   | 16.0          |
| watchOS 11.1                                            | watchos11.1                                   | 16.1          |
| Simulator - watchOS 9.4                                 | watchsimulator9.4                             | 14.3.1        |
| Simulator - watchOS 10.0                                | watchsimulator10.0                            | 15.0.1        |
| Simulator - watchOS 10.2                                | watchsimulator10.2                            | 15.1, 15.2    |
| Simulator - watchOS 10.4                                | watchsimulator10.4                            | 15.3          |
| Simulator - watchOS 10.5                                | watchsimulator10.5                            | 15.4          |
| Simulator - watchOS 11.0                                | watchsimulator11.0                            | 16.0          |
| Simulator - watchOS 11.1                                | watchsimulator11.1                            | 16.1          |
| visionOS 1.0                                            | xros1.0                                       | 15.2          |
| Simulator - visionOS 1.0                                | xrsimulator1.0                                | 15.2          |
| visionOS 1.1                                            | xros1.1                                       | 15.3          |
| Simulator - visionOS 1.1                                | xrsimulator1.1                                | 15.3          |
| Simulator - visionOS 1.2                                | xrsimulator1.2                                | 15.4          |
| visionOS 1.2                                            | xros1.2                                       | 15.4          |
| visionOS 2.0                                            | xros2.0                                       | 16.0          |
| Simulator - visionOS 2.0                                | xrsimulator2.0                                | 16.0          |
| Simulator - visionOS 2.1                                | xrsimulator2.1                                | 16.1          |
| visionOS 2.1                                            | xros2.1                                       | 16.1          |
| Asset Runtime SDK for macOS hosts targeting watchOS 9.4 | assetruntime.host.macosx.target.watchos9.4    | 14.3.1        |
| Asset Runtime SDK for macOS hosts targeting tvOS 16.4   | assetruntime.host.macosx.target.appletvos16.4 | 14.3.1        |
| Asset Runtime SDK for macOS hosts targeting iOS 16.4    | assetruntime.host.macosx.target.iphoneos16.4  | 14.3.1        |
| DriverKit 22.4                                          | driverkit22.4                                 | 14.3.1        |
| DriverKit 23.0                                          | driverkit23.0                                 | 15.0.1        |
| DriverKit 23.2                                          | driverkit23.2                                 | 15.1, 15.2    |
| DriverKit 23.4                                          | driverkit23.4                                 | 15.3          |
| DriverKit 23.5                                          | driverkit23.5                                 | 15.4          |
| DriverKit 24.0                                          | driverkit24.0                                 | 16.0          |
| DriverKit 24.1                                          | driverkit24.1                                 | 16.1          |

#### Installed Simulators
| OS           | Simulators                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| iOS 16.4     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)                                                                                                                                                                                                                                                             |
| iOS 17.0     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)                                                                                                                                                                                        |
| iOS 17.2     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)                                                                                                                                                                                        |
| iOS 17.4     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad Air 11-inch (M2)<br>iPad Air 13-inch (M2)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)<br>iPad Pro 11-inch (M4)<br>iPad Pro 13-inch (M4)                                                                                    |
| iOS 17.5     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad Air 11-inch (M2)<br>iPad Air 13-inch (M2)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)<br>iPad Pro 11-inch (M4)<br>iPad Pro 13-inch (M4)                                                                                    |
| iOS 18.0     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone 16<br>iPhone 16 Plus<br>iPhone 16 Pro<br>iPhone 16 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad Air 11-inch (M2)<br>iPad Air 13-inch (M2)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)<br>iPad Pro 11-inch (M4)<br>iPad Pro 13-inch (M4)               |
| iOS 18.1     | iPhone 14<br>iPhone 14 Plus<br>iPhone 14 Pro<br>iPhone 14 Pro Max<br>iPhone 15<br>iPhone 15 Plus<br>iPhone 15 Pro<br>iPhone 15 Pro Max<br>iPhone 16<br>iPhone 16 Plus<br>iPhone 16 Pro<br>iPhone 16 Pro Max<br>iPhone SE (3rd generation)<br>iPad (10th generation)<br>iPad Air (5th generation)<br>iPad Air 11-inch (M2)<br>iPad Air 13-inch (M2)<br>iPad mini (6th generation)<br>iPad Pro (11-inch) (4th generation)<br>iPad Pro (12.9-inch) (6th generation)<br>iPad Pro 11-inch (M4)<br>iPad Pro 13-inch (M4)               |
| tvOS 16.4    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 17.0    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 17.2    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 17.4    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 17.5    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 18.0    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| tvOS 18.1    | Apple TV<br>Apple TV 4K (3rd generation)<br>Apple TV 4K (3rd generation) (at 1080p)                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| watchOS 9.4  | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Ultra (49mm)                                                                                                                                                             |
| watchOS 10.0 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm)                                                                 |
| watchOS 10.2 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm)                                                                 |
| watchOS 10.4 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm)                                                                 |
| watchOS 10.5 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm)                                                                 |
| watchOS 11.0 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 10 (42mm)<br>Apple Watch Series 10 (46mm)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm) |
| watchOS 11.1 | Apple Watch SE (40mm) (2nd generation)<br>Apple Watch SE (44mm) (2nd generation)<br>Apple Watch Series 10 (42mm)<br>Apple Watch Series 10 (46mm)<br>Apple Watch Series 5 (40mm)<br>Apple Watch Series 5 (44mm)<br>Apple Watch Series 6 (40mm)<br>Apple Watch Series 6 (44mm)<br>Apple Watch Series 7 (41mm)<br>Apple Watch Series 7 (45mm)<br>Apple Watch Series 8 (41mm)<br>Apple Watch Series 8 (45mm)<br>Apple Watch Series 9 (41mm)<br>Apple Watch Series 9 (45mm)<br>Apple Watch Ultra (49mm)<br>Apple Watch Ultra 2 (49mm) |
| visionOS 1.0 | Apple Vision Pro                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| visionOS 1.1 | Apple Vision Pro                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| visionOS 1.2 | Apple Vision Pro                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| visionOS 2.0 | Apple Vision Pro                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| visionOS 2.1 | Apple Vision Pro                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

### Android
| Package Name               | Version                                                                                                                                                                                                                             |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Android Command Line Tools | 11.0                                                                                                                                                                                                                                |
| Android Emulator           | 35.1.21                                                                                                                                                                                                                             |
| Android SDK Build-tools    | 35.0.0<br>34.0.0<br>33.0.2 33.0.3                                                                                                                                                                                                   |
| Android SDK Platforms      | android-35 (rev 1)<br>android-34-ext8 (rev 1)<br>android-34-ext12 (rev 1)<br>android-34-ext11 (rev 1)<br>android-34-ext10 (rev 1)<br>android-34 (rev 3)<br>android-33-ext5 (rev 1)<br>android-33-ext4 (rev 1)<br>android-33 (rev 3) |
| Android SDK Platform-Tools | 35.0.2                                                                                                                                                                                                                              |
| Android Support Repository | 47.0.0                                                                                                                                                                                                                              |
| CMake                      | 3.22.1                                                                                                                                                                                                                              |
| Google Play services       | 49                                                                                                                                                                                                                                  |
| Google Repository          | 58                                                                                                                                                                                                                                  |
| NDK                        | 24.0.8215888<br>25.2.9519653<br>26.3.11579264 (default)<br>27.1.12297006                                                                                                                                                            |

#### Environment variables
| Name                    | Value                                               |
| ----------------------- | --------------------------------------------------- |
| ANDROID_HOME            | /Users/runner/Library/Android/sdk                   |
| ANDROID_NDK             | /Users/runner/Library/Android/sdk/ndk/26.3.11579264 |
| ANDROID_NDK_HOME        | /Users/runner/Library/Android/sdk/ndk/26.3.11579264 |
| ANDROID_NDK_LATEST_HOME | /Users/runner/Library/Android/sdk/ndk/27.1.12297006 |
| ANDROID_NDK_ROOT        | /Users/runner/Library/Android/sdk/ndk/26.3.11579264 |
| ANDROID_SDK_ROOT        | /Users/runner/Library/Android/sdk                   |
