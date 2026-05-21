package funkin.ds;

import haxe.Constraints.IMap;
import haxe.io.Bytes;
import haxe.zip.Compress;
import haxe.zip.Uncompress;

/**
 * A map wrapper that transparently compresses string values using zlib,
 * storing them as raw `Bytes` to reduce memory footprint.
 *
 * Values are compressed on `set` and decompressed on `get`, so callers
 * always work with plain strings while the underlying map holds only
 * compressed bytes.
 *
 * The backing map type (e.g. `Map<String, Bytes>`, `haxe.ds.StringMap`) is
 * supplied at construction time, keeping the key type fully generic.
 *
 * ```haxe
 * var map = new BytesMap();
 * map.set("dialogue", reallyLongJsonString);
 * trace(map.get("dialogue")); // original string, decompressed on the fly
 */
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class BytesMap {
	private static final COMPRESSION_LEVEL:Int = 9;

	private var _data: Map<String, Bytes>;

	/**
	 * Creates a new `BytesMap` backed by the given map instance.
	 *
	 * The backing map must be empty or already contain validly compressed
	 * `Bytes` values — raw strings stored directly will cause `get` to throw.
	 */
	public function new() {
		_data = new Map<String, Bytes>();
	}

	/**
	 * Returns the decompressed string for `k`, or `null` if the key is absent.
	 *
	 * @param k The key to look up.
	 * @return The original string passed to `set`, or `null`.
	 */
	public inline function get(k:String):Null<String> {
		var bytes = _data.get(k);
		return bytes == null ? null : Uncompress.run(bytes).toString();
	}

	/**
	 * Returns `true` if `k` is present in the map.
	 *
	 * @param k The key to test.
	 */
	public inline function exists(k:String):Bool
		return _data.exists(k);

	/**
	 * Returns an iterator over all keys currently in the map.
	 */
	public inline function keys():Iterator<String>
		return _data.keys();

	/**
	 * Returns an iterator over the raw compressed `Bytes` values.
	 *
	 * Note: values are **not** decompressed here. Use `get` to retrieve
	 * the original strings.
	 */
	public inline function iterator():Iterator<Bytes>
		return _data.iterator();

	/**
	 * Returns a key-value iterator over all entries.
	 *
	 * Values are the raw compressed `Bytes`, not the original strings.
	 */
	public inline function keyValueIterator():KeyValueIterator<String, Bytes>
		return _data.keyValueIterator();

	/**
	 * Returns a shallow copy of this map, wrapping a copy of the backing store.
	 *
	 * The compressed byte buffers themselves are not duplicated — only the
	 * map structure is cloned.
	 *
	 * @return A new `BytesMap` with the same entries.
	 */
	public function copy():BytesMap {
		var temp = new BytesMap();
		@:privateAccess temp._data = _data.copy();
		return temp;
	}

	/**
	 * Returns a human-readable string representation of the backing map.
	 *
	 * Values appear as raw `Bytes`, not decompressed strings.
	 */
	public inline function toString():String
		return _data.toString();

	/**
	 * Compresses `content` and stores it under `k`, replacing any existing value.
	 *
	 * Compression uses zlib at the maximum level (`9`), trading CPU time for
	 * the smallest possible byte footprint.
	 *
	 * @param k       The key to store the value under.
	 * @param content The plain string to compress and store.
	 */
	public function set(k:String, content:String):Void {
		var compressed = Compress.run(Bytes.ofString(content), COMPRESSION_LEVEL);
		_data.set(k, compressed);
	}

	/**
	 * Removes the entry for `k` from the map.
	 *
	 * @param k The key to remove.
	 * @return `true` if the key existed and was removed, `false` otherwise.
	 */
	public function remove(k:String):Bool
		return _data.remove(k);

	/**
	 * Removes all entries from the map.
	 */
	public function clear():Void
		_data.clear();
}
