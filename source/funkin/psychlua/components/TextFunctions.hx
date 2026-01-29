package funkin.psychlua.components;

import funkin.psychlua.ImplementUtils;

class TextFunctions
{
	public static function implement(funk)
	{
		var impl = ImplementUtils.make(funk);

		impl("makeLuaText", function(tag:String, ?text:String = '', ?width:Int = 0, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');

			LuaUtils.destroyObject(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			if (PlayState.instance != null)
				leText.cameras = [PlayState.instance.camHUD];
			leText.scrollFactor.set();
			leText.borderSize = 2;
			MusicBeatState.getVariables().set(tag, leText);
		});

		impl("setTextString", function(tag:String, text:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.text = text;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextString: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextSize", function(tag:String, size:Int)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.size = size;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextSize: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextWidth", function(tag:String, width:Float)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextWidth: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextHeight", function(tag:String, height:Float)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.fieldHeight = height;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextHeight: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextAutoSize", function(tag:String, value:Bool)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.autoSize = value;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextAutoSize: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextBorder", function(tag:String, size:Float, color:String, ?style:String = 'outline')
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				CoolUtil.setTextBorderFromString(obj, (size > 0 ? style : 'none'));
				if (size > 0)
					obj.borderSize = size;

				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			ImplementUtils.addTextToDebug("setTextBorder: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextColor", function(tag:String, color:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			ImplementUtils.addTextToDebug("setTextColor: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextFont", function(tag:String, newFont:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			ImplementUtils.addTextToDebug("setTextFont: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextItalic", function(tag:String, italic:Bool)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.italic = italic;
				return true;
			}
			ImplementUtils.addTextToDebug("setTextItalic: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setTextAlignment", function(tag:String, alignment:String = 'left')
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
					case 'justify':
						obj.alignment = JUSTIFY;
				}
				return true;
			}
			ImplementUtils.addTextToDebug("setTextAlignment: Object " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});

		impl("getTextString", function(tag:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null && obj.text != null)
			{
				return obj.text;
			}
			ImplementUtils.addTextToDebug("getTextString: Object " + tag + " doesn't exist!", FlxColor.RED);
			return null;
		});
		impl("getTextSize", function(tag:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				return obj.size;
			}
			ImplementUtils.addTextToDebug("getTextSize: Object " + tag + " doesn't exist!", FlxColor.RED);
			return -1;
		});
		impl("getTextFont", function(tag:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				return obj.font;
			}
			ImplementUtils.addTextToDebug("getTextFont: Object " + tag + " doesn't exist!", FlxColor.RED);
			return null;
		});
		impl("getTextWidth", function(tag:String)
		{
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null)
			{
				return obj.fieldWidth;
			}
			ImplementUtils.addTextToDebug("getTextWidth: Object " + tag + " doesn't exist!", FlxColor.RED);
			return 0;
		});

		impl("addLuaText", function(tag:String)
		{
			var text:FlxText = MusicBeatState.getVariables().get(tag);
			if (text != null)
				LuaUtils.getTargetInstance().add(text);
		});
		impl("removeLuaText", function(tag:String, destroy:Bool = true)
		{
			var variables = MusicBeatState.getVariables();
			var text:FlxText = variables.get(tag);
			if (text == null)
				return;

			var instance:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
			instance.remove(text, true);
			if (destroy)
			{
				text.destroy();
				variables.remove(tag);
			}
		});
	}
}
