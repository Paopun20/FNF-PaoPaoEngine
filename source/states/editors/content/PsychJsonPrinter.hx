package states.editors.content;

import haxe.format.JsonPrinter;

class PsychJsonPrinter extends JsonPrinter
{
	var ignoreTab:Array<String> = [];

	public static function print(o:Dynamic, ?ignoreTab:Array<String>):String
	{
		var p = new PsychJsonPrinter(null, '\t');
		if (ignoreTab != null)
			p.ignoreTab = ignoreTab;
		p.write("", o);
		return p.buf.toString();
	}

	override function fieldsString(v:Dynamic, fields:Array<String>)
	{
		writeObject(v, fields, false);
	}

	function isComplex(v:Dynamic):Bool
	{
		switch (Type.typeof(v))
		{
			case TObject:
				for (f in Reflect.fields(v))
					if (isComplex(Reflect.field(v, f)))
						return true;
				return false;

			case TClass(Array):
				for (i in (v : Array<Dynamic>))
					if (isComplex(i))
						return true;
				return false;

			case TClass(haxe.ds.StringMap):
				return true;

			default:
				return false;
		}
	}

	function writeObject(v:Dynamic, fields:Array<String>, forceMultiline:Bool)
	{
		addChar('{'.code);
		nind++;

		var first = true;
		for (f in fields)
		{
			var value = Reflect.field(v, f);
			if (Reflect.isFunction(value))
				continue;

			var singleLine = !forceMultiline && ignoreTab.contains(f) && !isComplex(value);

			if (!first)
				addChar(','.code);
			first = false;

			if (!singleLine)
			{
				newl();
				ipad();
			}
			else if (!pretty)
				addChar(' '.code);

			quote(f);
			addChar(':'.code);
			if (pretty)
				addChar(' '.code);

			writeValue(value, singleLine);
		}

		nind--;
		newl();
		ipad();
		addChar('}'.code);
	}

	function writeValue(v:Dynamic, singleLine:Bool)
	{
		switch (Type.typeof(v))
		{
			case TObject:
				writeObject(v, Reflect.fields(v), !singleLine);

			case TClass(Array):
				writeArray(v, !singleLine);

			case TClass(haxe.ds.StringMap):
				var map:haxe.ds.StringMap<Dynamic> = cast v;
				var o = {};
				for (k in map.keys())
					Reflect.setField(o, k, map.get(k));
				writeObject(o, Reflect.fields(o), true);

			default:
				write(null, v);
		}
	}

	function writeArray(a:Array<Dynamic>, forceMultiline:Bool)
	{
		addChar('['.code);
		nind++;

		var first = true;
		for (v in a)
		{
			if (!first)
				addChar(','.code);
			first = false;

			if (forceMultiline)
			{
				newl();
				ipad();
			}
			writeValue(v, !forceMultiline);
		}

		nind--;
		if (forceMultiline)
		{
			newl();
			ipad();
		}
		addChar(']'.code);
	}
}
