package funkin.backend.utils.macro;

import haxe.io.Bytes;
import haxe.io.Encoding;
import funkin.ds.BytesMap;
import haxe.Timer;
import Sys;
import sys.FileSystem;
#if macro
import haxe.io.Path;
import haxe.Json;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.io.Process;

using StringTools;

#if hxp
import hxp.*;
import lime.tools.*;
#end

enum FileModes {
	XML(data:Xml);
	HXP(data:Dynamic);
}
#end

#if !lime
#error "for lime project only"
#end
class UnsupportException extends haxe.Exception {}

/*
	Simple macro to build a source map of all .hx files in the project at compile time, based on the paths defined in Project.xml. This allows us to include source code in error logs without needing to read files at runtime, which is especially useful for platforms with limited file access or for packaging everything into a single binary.
	for lime Project.xml only
 */
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
final class SourceMap {
	private static function print(input:String, ?newLine:Bool = true):Void {
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

	private static function printRGB(r:Int, g:Int, b:Int, text:String, ?newLine:Bool = true):Void {
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

	macro public static function build():ExprOf<BytesMap> {
		var setExprs:Array<Expr> = [];
		var startTime = Timer.stamp();

		print("[Start Generating] Building source map from .hx files...");
		flush();

		for (path in (getSourcePaths()))
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
				collectFiles(path, path, setExprs);

		var endTime = Timer.stamp();
		print("[Done Generating] Time taken: " + (endTime - startTime) + " seconds");
		flush();

		return macro {
			var __map = new BytesMap();
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

	private static function getProjectFile():FileModes {
		var data:Dynamic;
		var xmlPath = "./Project.xml";
		var hxpPath = "./Project.hxp";

		if (FileSystem.exists(xmlPath)) {
			var content = File.getContent(xmlPath);

			var xml = try {
				Xml.parse(content);
			} catch (e:Dynamic) {
				null;
			};

			if (xml != null) {
				var data = xml.firstElement();
				if (data != null)
					return FileModes.XML(data);
			}
		}

		// todo: hxp check

		return FileModes.HXP(null);
	}

	private static function getSourcePaths():Array<String> {
		var paths:Array<String> = [];

		var mode = getProjectFile();

		switch (mode) {
			case XML(datas):
				for (node in datas) {
					if (node.nodeType != Xml.Element)
						continue;

					switch (node.nodeName) {
						case "source" | "classpath":
							// <source path="source"/>
							var path = resolvePathAttr(node);
							if (path != null && path != "") {
								paths.push(FileSystem.absolutePath(path));
							} else {
								printRGB(255, 165, 0, 'Invalid <source> path in Project.xml');
							}

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
			case HXP(_): // todo: do this shit
				throw new UnsupportException("Project.hxp is not supported yet");
		}

		return paths;
	}

	/*
		haxelib libpath lime:8.3.2 <- libName:version format if version is provided, otherwise just haxelib set version kicks it
		C:/HaxeToolkit/haxe/lib/lime/8,3,2/ <- output with trailing slash
	 */
	private static function resolveHaxelibPath(name:String, ?version:String):Null<String> {
		var libArg = (version != null && version != "") ? '$name:$version' : name;

		try {
			var process = new Process("haxelib", ["libpath", libArg]);
			var exitCode = process.exitCode();

			if (exitCode != 0) {
				return null;
			}

			var output = process.stdout.readAll();
			process.close();
			if (output == null || output.length == 0) {
				return null;
			}

			var outputStr = output.toString().trim();
			if (outputStr == "") {
				return null;
			}

			var lines = outputStr.split("\n");
			if (lines.length == 0) {
				return null;
			}

			var rootPath = FileSystem.absolutePath(Path.normalize(lines[0].trim()));

			var haxelibJson = Path.join([rootPath, "haxelib.json"]);

			if (!FileSystem.exists(haxelibJson)) {
				return rootPath;
			}

			var jsonContent = File.getContent(haxelibJson);
			if (jsonContent == null || jsonContent.trim() == "") {
				return rootPath;
			}

			var json:Dynamic = try Json.parse(jsonContent) catch (e:Dynamic) {
				return rootPath;
			};

			if (json == null) {
				return rootPath;
			}

			var classPath:String = Reflect.field(json, "classPath");
			if (classPath == null || classPath.trim() == "") {
				printRGB(180, 180, 180, 'Resolved $libArg -> [root] $rootPath');
				return rootPath;
			}

			var resolved = FileSystem.absolutePath(Path.join([rootPath, classPath]));
			printRGB(255, 255, 255, 'Resolved $libArg -> $resolved');
			return resolved;
		} catch (e:Dynamic) {
			printRGB(254, 215, 0, 'Failed resolving haxelib source path for $libArg: $e');
			return null;
		}
	}

	private static function splitString(s:String):Expr {
		if (s.length <= CHUNK_SIZE)
			return macro $v{s};

		// Use array join instead of nested + chains
		var chunks:Array<Expr> = [];
		var i = 0;
		while (i < s.length) {
			chunks.push(macro $v{s.substr(i, CHUNK_SIZE)});
			i += CHUNK_SIZE;
		}
		// Flat: [a, b, c].join("") instead of ((a + b) + c)
		return macro $a{chunks}.join("");
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
