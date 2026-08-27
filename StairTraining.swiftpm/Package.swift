// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "StairTraining",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "StairTraining",
            targets: ["StairTraining"],
            bundleIdentifier: "com.personal.stairtraining",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            // 如果你的 Xcode 版本沒有 `.bird` 這個內建圖示，
            // Xcode 會直接提示合法選項，換一個即可，不影響其他功能。
            appIcon: .placeholder(icon: .bird),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "StairTraining",
            path: "Sources/StairTraining"
        )
    ]
)
