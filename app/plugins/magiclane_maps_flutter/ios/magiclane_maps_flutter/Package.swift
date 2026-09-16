// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "magiclane_maps_flutter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "magiclane-maps-flutter",
            targets: ["magiclane_maps_flutter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/magiclane/magiclane-maps-sdk-flutter-ios.git",
            from: "3.1.11"
        )
    ],
    targets: [
        .target(
            name: "magiclane_maps_flutter",
            dependencies: [
                .product(name: "GEMKit", package: "magiclane-maps-sdk-flutter-ios")
            ],
            path: "Sources/magiclane_maps_flutter",
            cSettings: [
                .define("WITH_FLUTTER_FEATURE")
            ]
        )
    ]
)
