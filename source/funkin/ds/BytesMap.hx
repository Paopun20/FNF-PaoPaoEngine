package funkin.ds;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.EnumValueMap;
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
 * ```haxe
 * var map = new BytesMap<String>();
 * map.set("dialogue", reallyLongJsonString);
 * trace(map.get("dialogue")); // original string, decompressed on the fly
 * ```
 *
 * @param K The key type
 */
@:transitive
@:multiType(@:followWithAbstracts K)
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
abstract BytesMap<K>(IMap<K, Bytes>) {
	private static final COMPRESSION_LEVEL:Int = 9;

	/**
	 * Creates a new `BytesMap` backed by the given map instance.
	 *
	 * The backing map must be empty or already contain validly compressed
	 * `Bytes` values — raw strings stored directly will cause `get` to throw.
	 */
	public function new();

	/**
	 * Compresses `content` and stores it under `k`, replacing any existing value.
	 *
	 * Compression uses zlib at the maximum level (`9`), trading CPU time for
	 * the smallest possible byte footprint.
	 *
	 * @param key     The key to store the value under.
	 * @param content The plain string to compress and store.
	 */
	public inline function set(key:K, value:String):Void {
		var compressed = Compress.run(Bytes.ofString(value), COMPRESSION_LEVEL);
		this.set(key, compressed);
	}

	/**
	 * Returns the decompressed string for `k`, or `null` if the key is absent.
	 *
	 * @param k The key to look up.
	 * @return The original string passed to `set`, or `null`.
	 */
	@:arrayAccess public inline function get(k:K):Null<String> {
		var bytes = this.get(k);
		return bytes == null ? null : Uncompress.run(bytes).toString();
	}

	/**
	 * Returns `true` if `k` is present in the map.
	 *
	 * @param k The key to test.
	 */
	public inline function exists(k:K):Bool
		return this.exists(k);

	/**
	 * Removes the entry for `k` from the map.
	 *
	 * @param k The key to remove.
	 * @return `true` if the key existed and was removed, `false` otherwise.
	 */
	public function remove(k:K):Bool
		return this.remove(k);

	/**
	 * Returns an iterator over the raw compressed `Bytes` values.
	 *
	 * Note: values are **not** decompressed here. To retrieve original strings,
	 * iterate over `keys()` and call `get(key)` for each one instead.
	 */
	public inline function keys():Iterator<K>
		return this.keys();

	/**
	 * Returns a key-value iterator over all entries.
	 *
	 * Values are the raw compressed `Bytes`. To retrieve the original string
	 * for a given entry, call `get(key)` rather than decompressing the value
	 * directly.
	 */
	public inline function iterator():Iterator<Bytes>
		return this.iterator();

	/**
	 * Returns a key-value iterator over all entries.
	 *
	 * Values are the raw compressed `Bytes`, not the original strings.
	 */
	public inline function keyValueIterator():KeyValueIterator<K, Bytes>
		return this.keyValueIterator();

	/**
	 * Returns a shallow copy of this map, wrapping a copy of the backing store.
	 *
	 * The compressed byte buffers themselves are not duplicated — only the
	 * map structure is cloned.
	 *
	 * @return A new `BytesMap<K>` with the same entries.
	 */
	public inline function copy():BytesMap<K> {
		return cast this.copy();
	}

	/**
	 * Returns a human-readable string representation of the backing map.
	 *
	 * Values appear as raw `Bytes`, not decompressed strings.
	 */
	public inline function toString():String
		return this.toString();

	/**
	 * Removes all entries from the map.
	 */
	public function clear():Void
		this.clear();

	@:arrayAccess @:noCompletion public inline function arrayWrite(k:K, v:Bytes):Bytes {
		this.set(k, v);
		return v;
	}

	@:arrayAccess public inline function arrayRead(k:K):Null<String> {
		var bytes = this.get(k);
		return bytes == null ? null : Uncompress.run(bytes).toString();
	}

	@:to static inline function toStringMap(t:IMap<String, Bytes>):StringMap<Bytes>
		return cast t;

	@:to static inline function toIntMap(t:IMap<Int, Bytes>):IntMap<Bytes>
		return cast t;

	@:to static inline function toEnumValueMap<K:EnumValue>(t:IMap<K, Bytes>):EnumValueMap<K, Bytes>
		return cast t;

	@:to static inline function toObjectMap<K:{}>(t:IMap<K, Bytes>):ObjectMap<K, Bytes>
		return cast t;
}
