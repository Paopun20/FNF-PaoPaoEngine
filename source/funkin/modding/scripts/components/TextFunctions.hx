package funkin.modding.scripts.components;

import funkin.modding.scripts.utils.LuaUtils;

class TextFunctions {
	public static function implement(funk:Dynamic) {

		funk.set("makeLuaText", function(tag:String, ?text:String = '', ?width:Int = 0, ?x:Float = 0, ?y:Float = 0) {
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

		funk.set("setTextString", function(tag:String, text:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.text = text;
				return true;
			}
			CoolLog.warning("setTextString: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextSize", function(tag:String, size:Int) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.size = size;
				return true;
			}
			CoolLog.warning("setTextSize: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextWidth", function(tag:String, width:Float) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.fieldWidth = width;
				return true;
			}
			CoolLog.warning("setTextWidth: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextHeight", function(tag:String, height:Float) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.fieldHeight = height;
				return true;
			}
			CoolLog.warning("setTextHeight: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextAutoSize", function(tag:String, value:Bool) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.autoSize = value;
				return true;
			}
			CoolLog.warning("setTextAutoSize: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextBorder", function(tag:String, size:Float, color:String, ?style:String = 'outline') {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				CoolUtil.setTextBorderFromString(obj, (size > 0 ? style : 'none'));
				if (size > 0)
					obj.borderSize = size;

				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			CoolLog.warning("setTextBorder: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextColor", function(tag:String, color:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			CoolLog.warning("setTextColor: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextFont", function(tag:String, newFont:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.font = Paths.font(newFont);
				return true;
			}
			CoolLog.warning("setTextFont: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextItalic", function(tag:String, italic:Bool) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.italic = italic;
				return true;
			}
			CoolLog.warning("setTextItalic: Object " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase()) {
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
					case 'justify':
						obj.alignment = JUSTIFY;
				}
				return true;
			}
			CoolLog.warning("setTextAlignment: Object " + tag + " doesn't exist!");
			return false;
		});

		funk.set("getTextString", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null && obj.text != null) {
				return obj.text;
			}
			CoolLog.warning("getTextString: Object " + tag + " doesn't exist!");
			return null;
		});
		funk.set("getTextSize", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				return obj.size;
			}
			CoolLog.warning("getTextSize: Object " + tag + " doesn't exist!");
			return -1;
		});
		funk.set("getTextFont", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				return obj.font;
			}
			CoolLog.warning("getTextFont: Object " + tag + " doesn't exist!");
			return null;
		});
		funk.set("getTextWidth", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split),
				split[split.length - 1])) : LuaUtils.getObjectDirectly(split[0]);
			if (obj != null) {
				return obj.fieldWidth;
			}
			CoolLog.warning("getTextWidth: Object " + tag + " doesn't exist!");
			return 0;
		});

		funk.set("addLuaText", function(tag:String) {
			var text:FlxText = MusicBeatState.getVariables().get(tag);
			if (text != null)
				LuaUtils.getTargetInstance().add(text);
		});
		funk.set("removeLuaText", function(tag:String, destroy:Bool = true) {
			var variables = MusicBeatState.getVariables();
			var text:FlxText = variables.get(tag);
			if (text == null)
				return;

			var instance:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
			instance.remove(text, true);
			if (destroy) {
				text.destroy();
				variables.remove(tag);
			}
		});
	}
}
