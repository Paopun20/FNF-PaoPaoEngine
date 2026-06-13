/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe.format;

/**
	An implementation of JSON printer in Haxe.

	This class is used by `haxe.Json` when native JSON implementation
	is not available.

	@see https://haxe.org/manual/std-Json-encoding.html
**/
class JsonPrinter {
	/**
		Encodes `o`'s value and returns the resulting JSON string.

		If `replacer` is given and is not null, it is used to retrieve
		actual object to be encoded. The `replacer` function takes two parameters,
		the key and the value being encoded. Initial key value is an empty string.

		If `space` is given and is not null, the result will be pretty-printed.
		Successive levels will be indented by this string.
	**/
	static public function print(o:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		var printer = new JsonPrinter(replacer, space);
		printer.write("", o);
		return printer.buf.toString();
	}

	var buf:StringBuf;
	var replacer:(key:Dynamic, value:Dynamic) -> Dynamic;
	var indent:String;
	var pretty:Bool;
	var nind:Int;

	function new(replacer:(key:Dynamic, value:Dynamic) -> Dynamic, space:String) {
		this.replacer = replacer;
		this.indent = space;
		this.pretty = space != null;
		this.nind = 0;
		this.buf = new StringBuf();
	}

	inline function currentIndent():String {
		return StringTools.lpad("", indent, nind * indent.length);
	}

	inline function ipad():Void {
		if (pretty)
			add(currentIndent());
	}

	inline function newl():Void {
		if (pretty)
			addChar("\n".code);
	}

	function write(k:Dynamic, v:Dynamic) {
		if (replacer != null)
			v = replacer(k, v);

		switch (Type.typeof(v)) {
			case TUnknown:
				add('"???"');

			case TObject:
				objString(v);

			case TInt:
				add(Std.string(v));

			case TFloat:
				add(Math.isFinite(v) ? Std.string(v) : "null");

			case TFunction:
				add('"<fun>"');

			case TClass(c):
				writeClass(k, v, c);

			case TEnum(_):
				add(Std.string(Type.enumIndex(v)));

			case TBool:
				add(v ? "true" : "false");

			case TNull:
				add("null");
		}
	}

	function writeClass(k:Dynamic, v:Dynamic, c:Dynamic):Void {
		if (c == String) {
			quote(v);
			return;
		}

		if (c == Array) {
			writeArray(cast v);
			return;
		}

		if (c == haxe.ds.StringMap) {
			var map:haxe.ds.StringMap<Dynamic> = v;
			var obj = {};

			for (key in map.keys())
				Reflect.setField(obj, key, map.get(key));

			objString(obj);
			return;
		}

		if (c == Date) {
			var d:Date = v;
			quote(d.toString());
			return;
		}

		classString(v);
	}

	function writeArray(arr:Array<Dynamic>):Void {
		addChar("[".code);

		var len = arr.length;
		var last = len - 1;

		for (i in 0...len) {
			if (i == 0)
				nind++;
			else
				addChar(",".code);

			newl();
			ipad();

			write(i, arr[i]);

			if (i == last) {
				nind--;
				newl();
				ipad();
			}
		}

		addChar("]".code);
	}

	inline function addChar(c:Int):Void {
		buf.addChar(c);
	}

	inline function add(v:String):Void {
		buf.add(v);
	}

	function classString(v:Dynamic) {
		fieldsString(v, Type.getInstanceFields(Type.getClass(v)));
	}

	inline function objString(v:Dynamic) {
		fieldsString(v, Reflect.fields(v));
	}

	function fieldsString(v:Dynamic, fields:Array<String>) {
		addChar("{".code);

		var empty = true;

		for (field in fields) {
			var value = Reflect.field(v, field);

			if (Reflect.isFunction(value))
				continue;

			if (empty) {
				empty = false;
				nind++;
			} else {
				addChar(",".code);
			}

			newl();
			ipad();

			quote(field);

			addChar(":".code);

			if (pretty)
				addChar(" ".code);

			write(field, value);
		}

		if (!empty) {
			nind--;
			newl();
			ipad();
		}

		addChar("}".code);
	}

	static function escapeChar(c:Int):Null<String> {
		return switch (c) {
			case '"'.code: '\\"';
			case '\\'.code: '\\\\';
			case '\n'.code: '\\n';
			case '\r'.code: '\\r';
			case '\t'.code: '\\t';
			case 8: '\\b';
			case 12: '\\f';
			default: null;
		}
	}

	function quote(s:String) {
		addChar('"'.code);

		var i = 0;
		var length = s.length;

		while (i < length) {
			var c = StringTools.unsafeCodeAt(s, i++);

			var escaped = escapeChar(c);

			if (escaped != null) {
				add(escaped);
				continue;
			}

			addChar(c);
		}

		addChar('"'.code);
	}
}
