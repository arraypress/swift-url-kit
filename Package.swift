// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "swift-url-kit",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8), .visionOS(.v1)],
    products: [
        // One import for everything.
        .library(name: "URLKit", targets: ["URLKit"]),
        // Or just the piece you need.
        .library(name: "URLStripper", targets: ["URLStripper"]),
        .library(name: "URLValidator", targets: ["URLValidator"]),
        .library(name: "URLCore", targets: ["URLCore"]),
        // The one module that uses the network: follows shorteners and redirects.
        .library(name: "URLExpander", targets: ["URLExpander"]),
    ],
    targets: [
        // Shared: host matching, URL parts, redirect wrappers, shortener hosts.
        .target(name: "URLCore"),
        // Removes tracking from URLs.
        .target(name: "URLStripper", dependencies: ["URLCore"]),
        // Recognises platforms, extracts identifiers, reads link signals.
        .target(name: "URLValidator", dependencies: ["URLCore"]),
        // Umbrella — offline modules only; URLExpander is imported explicitly.
        .target(name: "URLKit", dependencies: ["URLCore", "URLStripper", "URLValidator"]),
        // Resolves where a link really goes. Network.
        .target(name: "URLExpander", dependencies: ["URLCore"]),

        .testTarget(name: "URLCoreTests", dependencies: ["URLCore"]),
        .testTarget(name: "URLStripperTests", dependencies: ["URLStripper"]),
        .testTarget(name: "URLValidatorTests", dependencies: ["URLValidator"]),
        .testTarget(name: "URLExpanderTests", dependencies: ["URLExpander"]),
    ]
)
