package funkin.utils.macro;

import haxe.ds.StringMap;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using StringTools;
#end

/*
Simple macro to build a source map of all .hx files in the project at compile time, based on the paths defined in Project.xml. This allows us to include source code in error logs without needing to read files at runtime, which is especially useful for platforms with limited file access or for packaging everything into a single binary.
 */
final class SourceMap
{
	macro public static function build():ExprOf<StringMap<String>>
	{
		var setExprs:Array<Expr> = [];

		for (path in getSourcePaths())
		{
			if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
				collectFiles(path, path, setExprs);
		}

		return macro
		{
			var __sourceMap = new StringMap<String>();
			$b{setExprs};
			__sourceMap;
		};
	}

	#if macro
	// MSVC limits string literals to ~16KB, so I chunk large files
	static final CHUNK_SIZE = 8000;
	
	static function resolvePathAttr(node:Xml):Null<String>
	{
		var path = node.get("path");
		if (path == null || path == "") path = node.get("name");
		return (path != null && path != "") ? sys.FileSystem.absolutePath(path) : null;
	}

	static function getSourcePaths():Array<String>
	{
		var paths:Array<String> = [];

		var xmlPath = "./Project.xml";
		if (!sys.FileSystem.exists(xmlPath))
		{
			Context.warning("SourceMap: Project.xml not found", Context.currentPos());
			return [sys.FileSystem.absolutePath("./source")];
		}

		var content = sys.io.File.getContent(xmlPath);
		var xml = try Xml.parse(content) catch (e:Dynamic)
		{
			Context.warning('SourceMap: Failed to parse Project.xml: $e', Context.currentPos());
			return [sys.FileSystem.absolutePath("./source")];
		};

		for (node in xml.firstElement())
		{
			if (node.nodeType != Xml.Element) continue;

			switch (node.nodeName)
			{
				case "haxelib":
					// <haxelib name="flixel"/>
					// <haxelib name="flixel" version="5.4.0"/>
					var name = node.get("name");
					var version = node.get("version"); // null if not set
					if (name != null && name != "")
					{
						var libPath = resolveHaxelibPath(name, version);
						if (libPath != null)
							paths.push(libPath);
						else
							Context.warning('SourceMap: Could not resolve haxelib $name:$version', Context.currentPos());
					}
				
				case "source" | "classpath":
					// <source path="source"/>
					var path = resolvePathAttr(node);
					if (path != null && path != "")
						paths.push(sys.FileSystem.absolutePath(path));
					else
						Context.warning('SourceMap: Invalid <source> path in Project.xml', Context.currentPos());

				default:
					// Just facking ignore other nodes
			}
		}

		if (paths.length == 0)
		{
			Context.warning("SourceMap: No paths found in Project.xml, falling back to ./source", Context.currentPos());
			paths.push(sys.FileSystem.absolutePath("./source"));
		}

		return paths;
	}

	static function resolveHaxelibPath(name:String, ?version:String):Null<String>
	{
		// haxelib path accepts "name:version" format
		var libArg = (version != null && version != "") ? '$name:$version' : name;

		try
		{
			var proc = new sys.io.Process("haxelib", ["path", libArg]);
			var output = proc.stdout.readAll().toString();
			var exitCode = proc.exitCode();
			proc.close();

			if (exitCode != 0)
			{
				Context.warning('SourceMap: haxelib path $libArg failed (exit $exitCode)', Context.currentPos());
				return null;
			}

			// First non-flag line of `haxelib path` output is the source directory
			for (line in output.split("\n"))
			{
				line = line.trim().replace("\\", "/");
				if (line == "" || line.startsWith("-")) continue;
				if (sys.FileSystem.exists(line) && sys.FileSystem.isDirectory(line))
				{
					Context.info('SourceMap: Resolved $libArg -> $line', Context.currentPos());
					return line;
				}
			}

			Context.warning('SourceMap: Could not resolve source path for haxelib $libArg', Context.currentPos());
			return null;
		}
		catch (e:Dynamic)
		{
			Context.warning('SourceMap: Exception resolving haxelib $libArg: $e', Context.currentPos());
			return null;
		}
	}

	static function splitString(s:String):Expr
	{
		if (s.length <= CHUNK_SIZE)
			return macro $v{s};

		var chunks:Array<Expr> = [];
		var i = 0;
		while (i < s.length)
		{
			var chunk = s.substr(i, CHUNK_SIZE);
			chunks.push(macro $v{chunk});
			i += CHUNK_SIZE;
		}
		// Fold chunks into a single string concatenation expression
		var result = chunks[0];
		for (i in 1...chunks.length)
			result = macro $result + $e{chunks[i]};

		return result;
	}

	static function collectFiles(base:String, dir:String, exprs:Array<Expr>):Void
	{
		var items = try sys.FileSystem.readDirectory(dir) catch (e:Dynamic) return;
		for (file in items)
		{
			var full = dir + "/" + file;
			if (sys.FileSystem.isDirectory(full))
			{
				collectFiles(base, full, exprs);
			}
			else if (file.endsWith(".hx"))
			{
				var key = full.substr(base.length + 1).replace("\\", "/");
				var content = try sys.io.File.getContent(full) catch (e:Dynamic) continue;
				exprs.push(macro __sourceMap.set($v{key}, ${splitString(content)}));
			}
		}
	}
	#end
}