package funkin.backend.utils.macro;

import haxe.io.Bytes;
import haxe.io.Encoding;
import funkin.ds.BytesMap;
import Sys;
import sys.FileSystem;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.io.Process;

using StringTools;
#end

/*
	Simple macro to build a source map of all .hx files in the project at compile time, based on the paths defined in Project.xml. This allows us to include source code in error logs without needing to read files at runtime, which is especially useful for platforms with limited file access or for packaging everything into a single binary.
	for lime Project.xml only
 */
final class SourceMap {
	private static function print(input:String, ?newLine:Bool=true):Void {
		Sys.stdout().writeString(input);
		if (newLine)
			Sys.stdout().writeString("\n");
	}

	private static inline function rgb(r:Int, g:Int, b:Int):String {
		return '\x1b[38;2;${r};${g};${b}m';
	}

	private static inline function reset():String {
		return '\x1b[0m';
	}

	private static function printRGB(r:Int, g:Int, b:Int, text:String, ?newLine:Bool=true):Void {
		print(rgb(r, g, b) + text + reset(), newLine);
	}

	private static function flush():Void {
		Sys.stdout().flush();
	}

	static function __init__():Void {
		print("███████╗ ██████╗ ██╗   ██╗██████╗  ██████╗███████╗███╗   ███╗ █████╗ ██████╗");
		print("██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔════╝████╗ ████║██╔══██╗██╔══██╗");
		print("███████╗██║   ██║██║   ██║██████╔╝██║     █████╗  ██╔████╔██║███████║██████╔╝");
		print("╚════██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║██╔══██║██╔═══╝");
		print("███████║╚██████╔╝╚██████╔╝██║  ██║╚██████╗███████╗██║ ╚═╝ ██║██║  ██║██║");
		print("╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝");
		flush();
		print("By PaoPao");
		flush();
	}

	macro public static function build():ExprOf<BytesMap<String>> {
		var setExprs:Array<Expr> = [];
		
		print("[Start Generating]");
		flush();

		for (path in (getSourcePaths()))
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
				collectFiles(path, path, setExprs);

		print("[Done Generating]");
		flush();

		return macro {
			var __map = new BytesMap<String>(new haxe.ds.StringMap());
			$b{setExprs};
			__map;
		};
	}

	#if macro
	// MSVC limits string literals to ~16KB, so I chunk large files
	private static final CHUNK_SIZE = 8000;

	private static function resolvePathAttr(node:Xml):Null<String> {
		var path = node.get("path");
		if (path == null || path == "")
			path = node.get("name");
		return (path != null && path != "") ? FileSystem.absolutePath(path) : null;
	}

	private static function getSourcePaths():Array<String> {
		var paths:Array<String> = [];

		var xmlPath = "./Project.xml";
		if (!FileSystem.exists(xmlPath)) {
			printRGB(255, 165, 0, "Project.xml not found");
			return [FileSystem.absolutePath("./source")];
		}

		var content = File.getContent(xmlPath);
		var xml = try Xml.parse(content) catch (e:Dynamic) {
			printRGB(255, 165, 0, 'Failed to parse Project.xml: $e');
			return [FileSystem.absolutePath("./source")];
		};

		for (node in xml.firstElement()) {
			if (node.nodeType != Xml.Element)
				continue;

			switch (node.nodeName) {
				case "source" | "classpath":
					// <source path="source"/>
					var path = resolvePathAttr(node);
					if (path != null && path != "")
						paths.push(FileSystem.absolutePath(path));
					else
						printRGB(255, 165, 0, 'Invalid <source> path in Project.xml');

				case "haxelib":
					// <haxelib name="flixel"/>
					// <haxelib name="flixel" version="5.4.0"/>
					var name = node.get("name");
					var version = node.get("version"); // null if not set
					if (name != null && name != "") {
						var libPath = resolveHaxelibPath(name, version);
						if (libPath != null)
							paths.push(libPath);
						else
							printRGB(255, 165, 0, 'Could not resolve haxelib $name:$version');
					}

				default:
					// Just facking ignore other nodes
			}
		}

		if (paths.length == 0) {
			printRGB(255, 165, 0, "No paths found in Project.xml, falling back to ./source");
			paths.push(FileSystem.absolutePath("./source"));
		}

		return paths;
	}

	private static function resolveHaxelibPath(name:String, ?version:String):Null<String> {
		// haxelib path accepts "name:version" format
		var libArg = (version != null && version != "") ? '$name:$version' : name;

		try {
			var proc = new Process("haxelib", ["path", libArg]);
			var output = proc.stdout.readAll().toString();
			var exitCode = proc.exitCode();
			proc.close();

			if (exitCode != 0) {
				printRGB(255, 0, 0, 'haxelib path $libArg failed (exit $exitCode)');
				return null;
			}

			// First non-flag line of `haxelib path` output is the source directory
			for (line in output.split("\n")) {
				line = line.trim().replace("\\", "/");
				if (line == "" || line.startsWith("-"))
					continue;
				if (FileSystem.exists(line) && FileSystem.isDirectory(line)) {
					printRGB(255, 255, 255, 'Resolved $libArg -> $line');
					return line;
				}
			}

			printRGB(254, 215, 0, 'Could not resolve source path for haxelib $libArg');
			return null;
		} catch (e:Dynamic) {
			printRGB(254, 215, 0, 'Exception resolving haxelib $libArg: $e');
			return null;
		}
	}

	private static function splitString(s:String):Expr {
		if (s.length <= CHUNK_SIZE)
			return macro $v{s};

		var chunks:Array<Expr> = [];
		var i = 0;
		while (i < s.length) {
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

	private static function collectFiles(base:String, dir:String, exprs:Array<Expr>):Void {
		var items = try FileSystem.readDirectory(dir) catch (e:Dynamic) return;
		for (file in items) {
			var full = dir + "/" + file;
			if (FileSystem.isDirectory(full)) {
				collectFiles(base, full, exprs);
			} else if (file.endsWith(".hx")) {
				var key = full.substr(base.length + 1).replace("\\", "/");
				var content = try File.getContent(full) catch (e:Dynamic) continue;

				// _init bypasses the read-only guard; base64 decode happens once at startup
				exprs.push(macro __map.set($v{key}, (${splitString(content)})));
			}
		}
	}
	#end
}
