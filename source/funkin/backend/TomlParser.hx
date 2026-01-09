package funkin.backend;

import cpp.RawFILE;
import cpp.RawFILE.*;
import cpp.RawPointer;
import hxtomlc17.Toml;
import hxtomlc17.TomlDatum;
import hxtomlc17.TomlResult;

class TomlParser
{
	var load:TomlResult;

	public function new(file:String)
	{
		var file = fopen(file, "r");
		var result:TomlResult = Toml.parseFile(fp);
		fclose(fp);
		if (!result.ok)
		{
			throw new Error("Failed to parse TOML file");
		}
	}
}
