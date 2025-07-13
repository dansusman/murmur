// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Murmur",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Murmur", targets: ["Murmur"])
    ],
    dependencies: [
        // No external dependencies for core functionality
        // All features use built-in macOS frameworks
    ],
    targets: [
        .executableTarget(
            name: "Murmur",
            dependencies: [],
            path: "Murmur",
            resources: [
                .process("Resources")
            ]
        )
    ]
)