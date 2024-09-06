import Foundation

/// Extensions on Foundation’s `Bundle` so you get `Path` rather than `String` or `URL`.
extension Bundle {
	/// Returns the path for requested resource in this bundle.
	public func path(forResource: String, ofType: String?) -> Path? {
		let f: (String?, String?) -> String? = path(forResource:ofType:)
		let str = f(forResource, ofType)
		return str.flatMap(Path.init)
	}

	/**
	  Returns the path for the shared-frameworks directory in this bundle.
	  - Note: This is typically `ShareFrameworks`
	 */
	public var sharedFrameworks: DynamicPath {
		sharedFrameworksPath.flatMap(DynamicPath.init) ?? defaultSharedFrameworksPath
	}

	/**
	  Returns the path for the private-frameworks directory in this bundle.
	  - Note: This is typically `Frameworks`
	 */
	public var privateFrameworks: DynamicPath {
		privateFrameworksPath.flatMap(DynamicPath.init) ?? defaultSharedFrameworksPath
	}

	/// Returns the path for the resources directory in this bundle.
	public var resources: DynamicPath {
		resourcePath.flatMap(DynamicPath.init) ?? defaultResourcesPath
	}

	/// Returns the path for this bundle.
	public var path: DynamicPath {
		DynamicPath(string: bundlePath)
	}

	/// Returns the executable for this bundle, if there is one, not all bundles have one hence `Optional`.
	public var executable: DynamicPath? {
		executablePath.flatMap(DynamicPath.init)
	}
}

/// Extensions on `String` that work with `Path` rather than `String` or `URL`
extension String {
	/// Initializes this `String` with the contents of the provided path.
	@inlinable
	public init<P: Pathish>(contentsOf path: P) throws {
		try self.init(contentsOfFile: path.string)
	}

	/// - Returns: `to` to allow chaining
	@inlinable
	@discardableResult
	public func write<P: Pathish>(to: P, atomically: Bool = false, encoding: String.Encoding = .utf8) throws -> P {
		try write(toFile: to.string, atomically: atomically, encoding: encoding)
		return to
	}
}

/// Extensions on `Data` that work with `Path` rather than `String` or `URL`
extension Data {
	/// Initializes this `Data` with the contents of the provided path.
	@inlinable
	public init<P: Pathish>(contentsOf path: P) throws {
		try self.init(contentsOf: path.url)
	}

	/// - Returns: `to` to allow chaining
	@inlinable
	@discardableResult
	public func write<P: Pathish>(to: P, atomically: Bool = false) throws -> P {
		let opts: NSData.WritingOptions
		if atomically {
			#if !os(Linux)
			opts = .atomicWrite
			#else
			opts = .atomic
			#endif
		} else {
			opts = []
		}
		try write(to: to.url, options: opts)
		return to
	}
}

/// Extensions on `FileHandle` that work with `Path` rather than `String` or `URL`
extension FileHandle {
	/// Initializes this `FileHandle` for reading at the location of the provided path.
	@inlinable
	public convenience init<P: Pathish>(forReadingAt path: P) throws {
		try self.init(forReadingFrom: path.url)
	}

	/// Initializes this `FileHandle` for writing at the location of the provided path.
	@inlinable
	public convenience init<P: Pathish>(forWritingAt path: P) throws {
		try self.init(forWritingTo: path.url)
	}

	/// Initializes this `FileHandle` for reading and writing at the location of the provided path.
	@inlinable
	public convenience init<P: Pathish>(forUpdatingAt path: P) throws {
		try self.init(forUpdating: path.url)
	}
}

extension Bundle {
	internal var defaultSharedFrameworksPath: DynamicPath {
		#if os(macOS)
		return path.Contents.Frameworks
		#elseif os(Linux)
		return path.lib
		#else
		return path.Frameworks
		#endif
	}

	internal var defaultResourcesPath: DynamicPath {
		#if os(macOS)
		return path.Contents.Resources
		#elseif os(Linux)
		return path.share
		#else
		return path
		#endif
	}
}
