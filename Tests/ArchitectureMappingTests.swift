//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@testable import SwiftSDKGenerator
import XCTest

class ArchitectureMappingTest: XCTestCase {
  /// Swift on macOS, Swift on Linux and Debian packages all use
  /// different names for the x86 and Arm architectures:
  ///
  ///                     |  x86_64    arm64
  ///    ------------------------------------
  ///    Swift macOS      |  x86_64    arm64
  ///    Swift Linux      |  x86_64  aarch64
  ///    Debian packages  |   amd64    arm64
  ///
  /// The right names must be used in the right places, such as
  /// in download URLs and paths within the SDK bundle.   These
  /// tests check several paths and URLs for each combination
  /// of build-time and run-time architecture.
  ///
  /// At present macOS is the only supported build environment
  /// and Linux is the only supported target environment.

  public func verifySDKSpec(
    buildTimeCPUArchitecture: Triple.CPU, // CPU architecture of the build system
    runTimeCPUArchitecture: Triple.CPU, // CPU architecture of the target

    artifactID: String, // Base name of the generated bundle
    llvmDownloadURL: String, // URL of the build-time LLVM package
    runtimeSwiftDownloadURL: String, // URL of the runtime Swift SDK

    artifactBundlePathSuffix: String, // Path to the generated bundle
    sdkDirPathSuffix: String // Path of the SDK within the bundle
  ) async throws {
    // LocalSwiftSDKGenerator constructs URLs and paths which depend on architectures
    let sdk = try await LocalSwiftSDKGenerator(
      // macOS is currently the only supported build environment
      buildTimeCPUArchitecture: buildTimeCPUArchitecture,

      // Linux is currently the only supported runtime environment
      runTimeCPUArchitecture: runTimeCPUArchitecture,

      // Remaining fields are placeholders which are the same for all
      // combinations of build and runtime architecture
      swiftVersion: "5.8-RELEASE",
      swiftBranch: nil,
      lldVersion: "16.0.4",
      ubuntuVersion: "22.04",
      shouldUseDocker: false,
      isVerbose: false
    )

    XCTAssertEqual(sdk.artifactID, artifactID, "Unexpected artifactID")

    // Verify download URLs
    let artifacts = sdk.downloadableArtifacts

    // The build-time Swift SDK is a multiarch package and so is always the same
    XCTAssertEqual(
      artifacts.buildTimeTripleSwift.remoteURL.absoluteString,
      "https://download.swift.org/swift-5.8-release/xcode/swift-5.8-RELEASE/swift-5.8-RELEASE-osx.pkg",
      "Unexpected build-time Swift SDK URL"
    )

    // LLVM provides ld.lld
    XCTAssertEqual(
      artifacts.buildTimeTripleLLVM.remoteURL.absoluteString,
      llvmDownloadURL,
      "Unexpected llvmDownloadURL"
    )

    // The Swift runtime must match the target architecture
    XCTAssertEqual(
      artifacts.runTimeTripleSwift.remoteURL.absoluteString,
      runtimeSwiftDownloadURL,
      "Unexpected runtimeSwiftDownloadURL"
    )

    // Verify paths within the bundle
    let paths = sdk.pathsConfiguration

    // The bundle path is not critical - it uses Swift's name
    // for the target architecture
    XCTAssertEqual(
      paths.artifactBundlePath.string,
      paths.sourceRoot.string + artifactBundlePathSuffix,
      "Unexpected artifactBundlePathSuffix"
    )

    // The SDK path must use Swift's name for the architecture
    XCTAssertEqual(
      paths.sdkDirPath.string,
      paths.artifactBundlePath.string + sdkDirPathSuffix,
      "Unexpected sdkDirPathSuffix"
    )
  }

  func testX86ToX86SDKGenerator() async throws {
    try await self.verifySDKSpec(
      buildTimeCPUArchitecture: .x86_64,
      runTimeCPUArchitecture: .x86_64,
      artifactID: "5.8-RELEASE_ubuntu_22.04_x86_64",
      llvmDownloadURL: "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.4/clang+llvm-16.0.4-x86_64-apple-darwin22.0.tar.xz",
      runtimeSwiftDownloadURL: "https://download.swift.org/swift-5.8-release/ubuntu2204/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04.tar.gz",
      artifactBundlePathSuffix: "/Bundles/5.8-RELEASE_ubuntu_22.04_x86_64.artifactbundle",
      sdkDirPathSuffix: "/5.8-RELEASE_ubuntu_22.04_x86_64/x86_64-unknown-linux-gnu/ubuntu-jammy.sdk"
    )
  }

  func testX86ToArmSDKGenerator() async throws {
    try await self.verifySDKSpec(
      buildTimeCPUArchitecture: .x86_64,
      runTimeCPUArchitecture: .arm64,
      artifactID: "5.8-RELEASE_ubuntu_22.04_aarch64",
      llvmDownloadURL: "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.4/clang+llvm-16.0.4-x86_64-apple-darwin22.0.tar.xz",
      runtimeSwiftDownloadURL: "https://download.swift.org/swift-5.8-release/ubuntu2204-aarch64/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04-aarch64.tar.gz",
      artifactBundlePathSuffix: "/Bundles/5.8-RELEASE_ubuntu_22.04_aarch64.artifactbundle",
      sdkDirPathSuffix: "/5.8-RELEASE_ubuntu_22.04_aarch64/aarch64-unknown-linux-gnu/ubuntu-jammy.sdk"
    )
  }

  func testArmToArmSDKGenerator() async throws {
    try await self.verifySDKSpec(
      buildTimeCPUArchitecture: .arm64,
      runTimeCPUArchitecture: .arm64,
      artifactID: "5.8-RELEASE_ubuntu_22.04_aarch64",
      llvmDownloadURL: "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.4/clang+llvm-16.0.4-arm64-apple-darwin22.0.tar.xz",
      runtimeSwiftDownloadURL: "https://download.swift.org/swift-5.8-release/ubuntu2204-aarch64/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04-aarch64.tar.gz",
      artifactBundlePathSuffix: "/Bundles/5.8-RELEASE_ubuntu_22.04_aarch64.artifactbundle",
      sdkDirPathSuffix: "/5.8-RELEASE_ubuntu_22.04_aarch64/aarch64-unknown-linux-gnu/ubuntu-jammy.sdk"
    )
  }

  func testArmToX86SDKGenerator() async throws {
    try await self.verifySDKSpec(
      buildTimeCPUArchitecture: .arm64,
      runTimeCPUArchitecture: .x86_64,
      artifactID: "5.8-RELEASE_ubuntu_22.04_x86_64",
      llvmDownloadURL: "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.4/clang+llvm-16.0.4-arm64-apple-darwin22.0.tar.xz",
      runtimeSwiftDownloadURL: "https://download.swift.org/swift-5.8-release/ubuntu2204/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04.tar.gz",
      artifactBundlePathSuffix: "/Bundles/5.8-RELEASE_ubuntu_22.04_x86_64.artifactbundle",
      sdkDirPathSuffix: "/5.8-RELEASE_ubuntu_22.04_x86_64/x86_64-unknown-linux-gnu/ubuntu-jammy.sdk"
    )
  }
}
