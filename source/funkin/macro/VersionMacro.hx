package funkin.macro;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

class VersionMacro
{
	public static macro function build(version:String = 'gitVersion.txt'):Array<Field>
	{
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		var versionValue = "unknown";
		
		try
		{
			if (FileSystem.exists(version))
			{
				versionValue = File.getContent(version).trim();
				if (versionValue == "")
					versionValue = "unknown";
			}
		}
		catch (e) {}

		for (field in fields)
		{
			if (field.meta != null)
			{
				var hasInjectVar = false;
				for (meta in field.meta)
				{
					if (meta.name == ":injectvar")
					{
						hasInjectVar = true;
						break;
					}
				}
				
				if (hasInjectVar)
				{
					field.kind = FVar(macro :String, macro $v{versionValue});
				}
			}
		}
		
		return fields;
	}
}