package funkin.modding.scripts.utils;

import haxe.Constraints.NotVoid;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Parser;
import paopao.hython.VM;
import paopao.hython.Bytecode;
import haxe.crypto.Sha256;
import haxe.io.Bytes;

enum CacheType
{
	HSCRIPT();
	PYTHON();
}

class CacheScript
{
	private static var hscriptCache:StringMap<Expr> = new StringMap<Expr>();
	private static var pythonCache:StringMap<CodeObject> = new StringMap<CodeObject>();

	public static function exists(key:String, type:CacheType):Bool
	{
		return switch (type)
		{
			case HSCRIPT: hscriptCache.exists(key);
			case PYTHON: pythonCache.exists(key);
		}
	}

	public static function get(key:String, type:CacheType):NotVoid
	{
		return switch (type)
		{
			case HSCRIPT: hscriptCache.get(key);
			case PYTHON: pythonCache.get(key);
		}
	}

	public static function set(key:String, expr:Dynamic, type:CacheType):Void
	{
		switch (type)
		{
			case HSCRIPT:
				hscriptCache.set(key, cast expr);
			case PYTHON:
				pythonCache.set(key, cast expr);
		}
	}

	public static function clear(type:CacheType):Void
	{
		switch (type)
		{
			case HSCRIPT:
				hscriptCache.clear();

			case PYTHON:
				pythonCache.clear();
		}
	}

	public static function hashCode(string:String):String
	{
		return Sha256.make(Bytes.ofString(string)).toHex();
	}
}

class CacheParser
{
	public static function parse(code:String, type:CacheType, ?origin:String):Dynamic
	{
		return switch (type)
		{
			case HSCRIPT:
				(() ->
				{
					var p = new Parser();
					p.allowJSON = true;
					p.allowMetadata = true;
					p.allowTypes = true;
					return p;
				})().parseString(code, origin);

			case PYTHON:
				VM.compileSource(code);
		}
	}
}
