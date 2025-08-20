// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "precrastination",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    targets: [
        .executableTarget(
            name: "precrastination",
            dependencies: [
                "Alamofire"
            ]
        ),
    ]
)
