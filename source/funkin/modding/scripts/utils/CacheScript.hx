package funkin.modding.scripts.utils;

import haxe.ds.StringMap;
#if HSCRIPT_ALLOWED
import hscript.Expr;
import hscript.Parser;
#end
#if PYTHON_ALLOWED
import paopao.hython.Expr as PyExpr;
import paopao.hython.Parser as PyParser;
#end
import haxe.crypto.Sha256;
import haxe.io.Bytes;

enum CacheType {
	HSCRIPT;
	PYTHON;
}

@:nullSafety(Strict)
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class CacheScript {
	private static var hscriptCache:StringMap<Expr> = new StringMap<Expr>();
	private static var pythonCache:StringMap<PyExpr> = new StringMap<PyExpr>();

	public static function exists(key:String, type:CacheType):Bool {
		return switch (type) {
			case HSCRIPT: hscriptCache.exists(key);
			case PYTHON: pythonCache.exists(key);
		}
	}

	public static function get(key:String, type:CacheType):Dynamic {
		return switch (type) {
			case HSCRIPT:
				hscriptCache.exists(key) ? hscriptCache.get(key) : null;

			case PYTHON:
				pythonCache.exists(key) ? pythonCache.get(key) : null;
		}
	}

	public static function set(key:String, expr:Dynamic, type:CacheType):Void {
		switch (type) {
			case HSCRIPT:
				hscriptCache.set(key, cast expr);

			case PYTHON:
				pythonCache.set(key, cast expr);
		}
	}

	public static function clear(type:CacheType):Void {
		switch (type) {
			case HSCRIPT:
				hscriptCache.clear();

			case PYTHON:
				pythonCache.clear();
		}
	}

	public static function clearCache():Void {
		hscriptCache.clear();
		pythonCache.clear();
	}

	public static function hashCode(string:String):String {
		return Sha256.make(Bytes.ofString(string)).toHex();
	}
}

@:nullSafety(Strict)
class CacheParser {
	public static function parse(code:String, type:CacheType, ?origin:String):Dynamic {
		return switch (type) {
			case HSCRIPT:
				var p = new Parser();
				p.allowJSON = true;
				p.allowMetadata = true;
				p.allowTypes = true;
				p.parseString(code, origin);

			case PYTHON:
				var p = new PyParser();
				p.parseString(code);
		}
	}
}
