// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "StatusphereKit",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "StatusphereKit", targets: ["StatusphereKit"])
  ],
  dependencies: [
    // 0.44.5 is the first release that allows swift-crypto 5, which oauth4swift requires.
    .package(url: "https://github.com/nnabeyang/swift-atproto.git", from: "0.44.5"),
    .package(url: "https://github.com/germ-network/AtprotoOAuth.git", from: "0.7.0"),
    .package(url: "https://github.com/germ-network/AtprotoClient.git", from: "0.12.0"),
    .package(url: "https://github.com/germ-network/AtprotoTypes.git", from: "0.7.0"),
    .package(url: "https://github.com/germ-network/GermConvenience.git", from: "0.14.0"),
    .package(url: "https://github.com/germ-network/oauth4swift.git", from: "0.9.0"),
    .package(url: "https://github.com/germ-network/swift-secret-bytes.git", from: "0.6.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
  ],
  targets: [
    .target(
      name: "StatusphereKit",
      dependencies: [
        .product(name: "SwiftAtproto", package: "swift-atproto"),
        .product(name: "AtprotoOAuth", package: "AtprotoOAuth"),
        .product(name: "AtprotoClient", package: "AtprotoClient"),
        .product(name: "AtprotoTypes", package: "AtprotoTypes"),
        .product(name: "GermConvenience", package: "GermConvenience"),
        .product(name: "GermConvenienceHTTP", package: "GermConvenience"),
        .product(name: "GermConvenienceURLSession", package: "GermConvenience"),
        .product(name: "OAuth4Swift", package: "oauth4swift"),
        .product(name: "SecretBytes", package: "swift-secret-bytes"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
      ]
    )
  ]
)
