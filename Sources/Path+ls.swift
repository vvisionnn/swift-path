import Foundation

extension Path {
	/// The builder for `Path.find()`
	public class Finder {
		fileprivate init(path: Path) {
			self.path = path
			self.enumerator = FileManager.default.enumerator(atPath: path.string)
		}

		/// The `path` find operations operate on.
		public let path: Path

		private let enumerator: FileManager.DirectoryEnumerator!

		/// The range of directory depths for which the find operation will return entries.
		public private(set) var depth: ClosedRange<Int> = 1 ... Int.max {
			didSet {
				if depth.lowerBound < 0 {
					depth = 0 ... depth.upperBound
				}
			}
		}

		/// The kinds of filesystem entries find operations will return.
		public var types: Set<EntryType> {
			_types ?? Set(EntryType.allCases)
		}

		private var _types: Set<EntryType>?

		/// The file extensions find operations will return. Files *and* directories unless you filter for `kinds`.
		public private(set) var extensions: Set<String>?

		/// Whether to return hidden files
		public var hidden: Bool = true
	}
}

extension Path.Finder: Sequence, IteratorProtocol {
	public func next() -> Path? {
		guard let enumerator = enumerator else {
			return nil
		}
		while let relativePath = enumerator.nextObject() as? String {
			let path = path / relativePath

			#if !os(Linux) || swift(>=5.0)
			if enumerator.level > depth.upperBound {
				enumerator.skipDescendants()
				continue
			}
			if enumerator.level < depth.lowerBound {
				continue
			}

			if !hidden, path.basename().hasPrefix(".") {
				enumerator.skipDescendants()
				continue
			}
			#endif
			if let type = path.type, !types.contains(type) { continue }
			if let exts = extensions, !exts.contains(path.extension) { continue }
			return path
		}
		return nil
	}

	public typealias Element = Path
}

extension Path.Finder {
	/// A max depth of `0` returns only the path we are searching, `1` is that directory’s listing.
	public func depth(max maxDepth: Int) -> Path.Finder {
		#if os(Linux) && !swift(>=5.0)
		fputs("warning: depth not implemented for Swift < 5\n", stderr)
		#endif
		depth = Swift.min(maxDepth, depth.lowerBound) ... maxDepth
		return self
	}

	/// A min depth of `0` also returns the path we are searching, `1` is that directory’s listing. Default is `1` thus not returning ourself.
	public func depth(min minDepth: Int) -> Path.Finder {
		#if os(Linux) && !swift(>=5.0)
		fputs("warning: depth not implemented for Swift < 5\n", stderr)
		#endif
		depth = minDepth ... Swift.max(depth.upperBound, minDepth)
		return self
	}

	/// A max depth of `0` returns only the path we are searching, `1` is that directory’s listing.
	/// A min depth of `0` also returns the path we are searching, `1` is that directory’s listing. Default is `1` thus not returning ourself.
	public func depth(_ rng: Range<Int>) -> Path.Finder {
		#if os(Linux) && !swift(>=5.0)
		fputs("warning: depth not implemented for Swift < 5\n", stderr)
		#endif
		depth = rng.lowerBound ... (rng.upperBound - 1)
		return self
	}

	/// A max depth of `0` returns only the path we are searching, `1` is that directory’s listing.
	/// A min depth of `0` also returns the path we are searching, `1` is that directory’s listing. Default is `1` thus not returning ourself.
	public func depth(_ rng: ClosedRange<Int>) -> Path.Finder {
		#if os(Linux) && !swift(>=5.0)
		fputs("warning: depth not implemented for Swift < 5\n", stderr)
		#endif
		depth = rng
		return self
	}

	/// Multiple calls will configure the Finder with multiple kinds.
	public func type(_ type: Path.EntryType) -> Path.Finder {
		_types = _types ?? []
		_types!.insert(type)
		return self
	}

	/// Multiple calls will configure the Finder with for multiple extensions
	public func `extension`(_ ext: String) -> Path.Finder {
		extensions = extensions ?? []
		extensions!.insert(ext)
		return self
	}

	/// Whether to skip hidden files and folders.
	public func hidden(_ hidden: Bool) -> Path.Finder {
		#if os(Linux) && !swift(>=5.0)
		fputs("warning: hidden not implemented for Swift < 5\n", stderr)
		#endif
		self.hidden = hidden
		return self
	}

	/// The return type for `Path.Finder`
	public enum ControlFlow {
		/// Stop enumerating this directory, return to the parent.
		case skip
		/// Stop enumerating all together.
		case abort
		/// Keep going.
		case `continue`
	}

	/// Enumerate, one file at a time.
	public func execute(_ closure: (Path) throws -> ControlFlow) rethrows {
		while let path = next() {
			switch try closure(path) {
			case .skip:
				#if !os(Linux) || swift(>=5.0)
				enumerator.skipDescendants()
				#else
				fputs("warning: skip is not implemented for Swift < 5.0\n", stderr)
				#endif
			case .abort:
				return
			case .continue:
				continue
			}
		}
	}
}

extension Pathish {
	// MARK: Directory Listing

	/**
	 Same as the `ls` command ∴ output is ”shallow” and unsorted.
	 - Note: as per `ls`, by default we do *not* return hidden files. Specify `.a` for hidden files.
	 - Parameter options: Configure the listing.
	 - Important: On Linux the listing is always `ls -a`
	 */
	public func ls(_ options: ListDirectoryOptions? = nil) -> [Path] {
		guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
			fputs("warning: could not list: \(self)\n", stderr)
			return []
		}
		return urls.compactMap { url in
			guard let path = Path(url.path) else { return nil }
			if options != .a, path.basename().hasPrefix(".") { return nil }
			// ^^ we don’t use the Foundation `skipHiddenFiles` because it considers weird things hidden and we are mirroring `ls`
			return path
		}.sorted()
	}

	/// Recursively find files under this path. If the path is a file, no files will be found.
	public func find() -> Path.Finder {
		.init(path: Path(self))
	}
}

/// Convenience functions for the arrays of `Path`
extension Array where Element == Path {
	/// Filters the list of entries to be a list of Paths that are directories. Symlinks to directories are not returned.
	public var directories: [Path] {
		filter {
			$0.isDirectory
		}
	}

	/// Filters the list of entries to be a list of Paths that exist and are *not* directories. Thus expect symlinks, etc.
	/// - Note: symlinks that point to files that do not exist are *not* returned.
	public var files: [Path] {
		filter {
			switch $0.type {
			case .directory?, .none:
				return false
			case .file?, .symlink?:
				return true
			}
		}
	}
}

/// Options for `Path.ls(_:)`
public enum ListDirectoryOptions {
	/// Lists hidden files also
	case a
}
