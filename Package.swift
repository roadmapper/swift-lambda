// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
   
import PackageDescription
   
let package = Package(
  name: "SquareNumber",
  platforms: [
      .macOS(.v10_15),
  ],
  products: [
    .executable(name: "SquareNumber", targets: ["SquareNumber"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.2.0")),
    .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0")
  ],
  targets: [
    .target(
      name: "SquareNumber",
      dependencies: [
        .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
        .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
        .product(name: "PostgresKit", package: "postgres-kit"),
      ]
    ),
  ]
)
