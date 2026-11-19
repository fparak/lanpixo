// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LanpixoCore",
    products: [.library(name: "LanpixoCore", targets: ["LanpixoCore"])],
    targets: [
        .target(name: "LanpixoCore", path: "Lanpixo/Core"),
        .testTarget(name: "LanpixoCoreTests", dependencies: ["LanpixoCore"], path: "Tests")
    ]
)
