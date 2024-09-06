extension Path: CustomStringConvertible {
	/// Returns `Path.string`
	public var description: String {
		string
	}
}

extension Path: CustomDebugStringConvertible {
	/// Returns eg. `Path(string: "/foo")`
	public var debugDescription: String {
		"Path(\(string))"
	}
}

extension DynamicPath: CustomStringConvertible {
	/// Returns `Path.string`
	public var description: String {
		string
	}
}

extension DynamicPath: CustomDebugStringConvertible {
	/// Returns eg. `Path(string: "/foo")`
	public var debugDescription: String {
		"Path(\(string))"
	}
}
