package funkin.modding.scripts;

import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Parser;
import paopao.hython.Expr as PyExpr;
import paopao.hython.Parser as PyParser;
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
	private static var pythonCache:StringMap<PyExpr> = new StringMap<PyExpr>();

	public static function exists(key:String, type:CacheType):Bool
	{
		return switch (type)
		{
			case HSCRIPT: hscriptCache.exists(key);
			case PYTHON: pythonCache.exists(key);
		}
	}

	public static function get(key:String, type:CacheType):Dynamic
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
	public static var hscriptParser = (() ->
	{
		var p = new Parser();
		p.allowJSON = true;
		p.allowMetadata = true;
		p.allowTypes = true;
		return p;
	})();
	public static var pythonParser = (() ->
	{
		var p = new PyParser();
		return p;
	})();

	public static function parse(code:String, type:CacheType):Dynamic
	{
		return switch (type)
		{
			case HSCRIPT:
				hscriptParser.parseString(code);

			case PYTHON:
				pythonParser.parseString(code);
		}
	}
}
