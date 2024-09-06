import Foundation

/// The `extension` that provides static properties that are common directories.
private enum Foo {
	// MARK: Common Directories

	/// Returns a `Path` containing `FileManager.default.currentDirectoryPath`.
	static var cwd: DynamicPath {
		.init(string: FileManager.default.currentDirectoryPath)
	}

	/// Returns a `Path` representing the root path.
	static var root: DynamicPath {
		.init(string: "/")
	}

	#if swift(>=5.3)
	public static func source(for filePath: String = #filePath) -> (file: DynamicPath, directory: DynamicPath) {
		let file = DynamicPath(string: filePath)
		return (file: file, directory: .init(file.parent))
	}
	#else
	public static func source(for filePath: String = #file) -> (file: DynamicPath, directory: DynamicPath) {
		let file = DynamicPath(string: filePath)
		return (file: file, directory: .init(file.parent))
	}
	#endif

	/// Returns a `Path` representing the user’s home directory
	static var home: DynamicPath {
		let string: String
		#if os(macOS)
		if #available(OSX 10.12, *) {
			string = FileManager.default.homeDirectoryForCurrentUser.path
		} else {
			string = NSHomeDirectory()
		}
		#else
		string = NSHomeDirectory()
		#endif
		return .init(string: string)
	}

	/// Helper to allow search path and domain mask to be passed in.
	private static func path(for searchPath: FileManager.SearchPathDirectory) -> DynamicPath {
		#if os(Linux)
		// the urls(for:in:) function is not implemented on Linux
		// TODO: strictly we should first try to use the provided binary tool

		let foo = { ProcessInfo.processInfo.environment[$0].flatMap(Path.init).map(DynamicPath.init) ?? $1 }

		switch searchPath {
		case .documentDirectory:
			return Path.home.Documents
		case .applicationSupportDirectory:
			return foo("XDG_DATA_HOME", Path.home[dynamicMember: ".local/share"])
		case .cachesDirectory:
			return foo("XDG_CACHE_HOME", Path.home[dynamicMember: ".cache"])
		default:
			fatalError()
		}
		#else
		guard let pathString = FileManager.default.urls(for: searchPath, in: .userDomainMask).first?.path else { return defaultUrl(for: searchPath) }
		return DynamicPath(string: pathString)
		#endif
	}

	/**
	 The root for user documents.
	 - Note: There is no standard location for documents on Linux, thus we return `~/Documents`.
	 - Note: You should create a subdirectory before creating any files.
	 */
	static var documents: DynamicPath {
		path(for: .documentDirectory)
	}

	/**
	 The root for cache files.
	 - Note: On Linux this is `XDG_CACHE_HOME`.
	 - Note: You should create a subdirectory before creating any files.
	 */
	static var caches: DynamicPath {
		path(for: .cachesDirectory)
	}

	/**
	 For data that supports your running application.
	 - Note: On Linux is `XDG_DATA_HOME`.
	 - Note: You should create a subdirectory before creating any files.
	 */
	static var applicationSupport: DynamicPath {
		path(for: .applicationSupportDirectory)
	}
}

#if !os(Linux)
func defaultUrl(for searchPath: FileManager.SearchPathDirectory) -> DynamicPath {
	switch searchPath {
	case .documentDirectory:
		return Path.home.Documents
	case .applicationSupportDirectory:
		return Path.home.Library[dynamicMember: "Application Support"]
	case .cachesDirectory:
		return Path.home.Library.Caches
	default:
		fatalError()
	}
}
#endif

/// The `extension` that provides static properties that are common directories.
#if swift(>=5.5)
extension Pathish where Self == Path {
	public static var home: DynamicPath { Foo.home }
	public static var root: DynamicPath { Foo.root }
	public static var cwd: DynamicPath { Foo.cwd }
	public static var documents: DynamicPath { Foo.documents }
	public static var caches: DynamicPath { Foo.caches }
	public static var applicationSupport: DynamicPath { Foo.applicationSupport }
	public static func source(for filePath: String = #filePath) -> (file: DynamicPath, directory: DynamicPath) {
		Foo.source(for: filePath)
	}
}
#else
extension Path {
	public static var home: DynamicPath { Foo.home }
	public static var root: DynamicPath { Foo.root }
	public static var cwd: DynamicPath { Foo.cwd }
	public static var documents: DynamicPath { Foo.documents }
	public static var caches: DynamicPath { Foo.caches }
	public static var applicationSupport: DynamicPath { Foo.applicationSupport }
	#if swift(>=5.3)
	public static func source(for filePath: String = #filePath) -> (file: DynamicPath, directory: DynamicPath) {
		Foo.source(for: filePath)
	}
	#else
	public static func source(for file: String = #file) -> (file: DynamicPath, directory: DynamicPath) {
		Foo.source(for: file)
	}
	#endif
}
#endif
