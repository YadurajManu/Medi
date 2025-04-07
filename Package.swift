// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Medi",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Medi",
            targets: ["Medi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "Medi",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAppCheck", package: "firebase-ios-sdk"),
            ]),
    ]
) 