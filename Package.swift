// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "RealmConverter",
	platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "RealmConverter",
			targets: ["RealmConverter"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift", from: "10.25.0"),
        .package(url: "https://github.com/Daniel1of1/CSwiftV", branch: "develop"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "RealmConverter",
            dependencies: [
                .product(name: "Realm", package: "realm-swift"),
                .product(name: "RealmSwift", package: "realm-swift"),
                "PathKit",
                "CSwiftV"
            ],
			path: "RealmConverter",
            exclude: ["Info.plist", "RealmConverter.h"]
		)
    ],
	swiftLanguageVersions: [.v5]
)
