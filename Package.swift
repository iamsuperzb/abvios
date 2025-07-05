// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ABVios",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // SDWebImageSwiftUI for async image loading with cache
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.0"),
    ],
    targets: [
        .target(
            name: "ABVios",
            dependencies: [
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
            ]
        ),
        .testTarget(
            name: "ABViosTests",
            dependencies: ["ABVios"]
        ),
    ]
)