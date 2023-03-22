//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

enum GeneratorError: Error {
  case unknownUbuntuVersion(String)
  case unknownMacOSVersion(String)
  case unknownCPUArchitecture(String)
}

extension GeneratorError: CustomStringConvertible {
  var description: String {
    switch self {
    case let .unknownUbuntuVersion(version):
      return "Ubuntu Linux version `\(version)` is not supported by this generator."
    case let .unknownMacOSVersion(version):
      return "macOS version `\(version)` is not supported by this generator."
    case let .unknownCPUArchitecture(cpu):
      return "CPU architecture `\(cpu)` is not supported by this generator."
    }
  }
}
