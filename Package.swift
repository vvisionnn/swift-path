// swift-tools-version:5.9
import PackageDescription

let package = Package(
	name: "Path",
	products: [
		.library(name: "Path", targets: ["Path"]),
	],
	targets: [
		.target(name: "Path", path: "Sources"),
		.testTarget(name: "PathTests", dependencies: ["Path"]),
	]
)

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings!.append(contentsOf: [
		.enableExperimentalFeature("StrictConcurrency"),
		.enableUpcomingFeature("InferSendableFromCaptures"),
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("BareSlashRegexLiterals"),
		.enableUpcomingFeature("ConciseMagicFile"),
		.enableUpcomingFeature("ForwardTrailingClosures"),
		.enableUpcomingFeature("ImplicitOpenExistentials"),
		.enableUpcomingFeature("DisableOutwardActorInference"),
	])
}
