package funkin.psychlua;

import flixel.util.FlxSave;
import openfl.utils.Assets;
import funkin.psychlua.ImplementUtils;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions
{
	public static function implement(funk)
	{
		var impl = ImplementUtils.make(funk);

		// Keyboard & Gamepads
		impl("keyboardJustPressed", function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		impl("keyboardPressed", function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		impl("keyboardReleased", function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		impl("anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name));
		impl("anyGamepadPressed", function(name:String) FlxG.gamepads.anyPressed(name));
		impl("anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name));

		impl("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		impl("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		impl("gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		impl("gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		impl("gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		impl("keyJustPressed", function(name:String = '')
		{
			name = name.toLowerCase().trim();
			switch (name)
			{
				case 'left':
					return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down':
					return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up':
					return PlayState.instance.controls.NOTE_UP_P;
				case 'right':
					return PlayState.instance.controls.NOTE_RIGHT_P;
				default:
					return PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
		impl("keyPressed", function(name:String = '')
		{
			name = name.toLowerCase().trim();
			switch (name)
			{
				case 'left':
					return PlayState.instance.controls.NOTE_LEFT;
				case 'down':
					return PlayState.instance.controls.NOTE_DOWN;
				case 'up':
					return PlayState.instance.controls.NOTE_UP;
				case 'right':
					return PlayState.instance.controls.NOTE_RIGHT;
				default:
					return PlayState.instance.controls.pressed(name);
			}
			return false;
		});
		impl("keyReleased", function(name:String = '')
		{
			name = name.toLowerCase().trim();
			switch (name)
			{
				case 'left':
					return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down':
					return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up':
					return PlayState.instance.controls.NOTE_UP_R;
				case 'right':
					return PlayState.instance.controls.NOTE_RIGHT_R;
				default:
					return PlayState.instance.controls.justReleased(name);
			}
			return false;
		});

		// Save data management
		impl("initSaveData", function(name:String, ?folder:String = 'psychenginemods')
		{
			var variables = MusicBeatState.getVariables();
			if (!variables.exists('save_$name'))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				variables.set('save_$name', save);
				return;
			}
			ImplementUtils.addTextToDebug('initSaveData: Save file already initialized: ' + name, FlxColor.RED);
		});
		impl("flushSaveData", function(name:String)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				variables.get('save_$name').flush();
				return;
			}
			ImplementUtils.addTextToDebug('flushSaveData: Save file not initialized: ' + name, FlxColor.RED);
		});
		impl("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				var saveData = variables.get('save_$name').data;
				if (Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			ImplementUtils.addTextToDebug('getDataFromSave: Save file not initialized: ' + name, FlxColor.RED);
			return defaultValue;
		});
		impl("setDataFromSave", function(name:String, field:String, value:Dynamic)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				Reflect.setField(variables.get('save_$name').data, field, value);
				return;
			}
			ImplementUtils.addTextToDebug('setDataFromSave: Save file not initialized: ' + name, FlxColor.RED);
		});
		impl("eraseSaveData", function(name:String)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				variables.get('save_$name').erase();
				return;
			}
			ImplementUtils.addTextToDebug('eraseSaveData: Save file not initialized: ' + name, FlxColor.RED);
		});

		// File management
		impl("checkFileExists", function(filename:String, ?absolute:Bool = false)
		{
			#if MODS_ALLOWED
			if (absolute)
				return FileSystem.exists(filename);

			return FileSystem.exists(Paths.getPath(filename, TEXT));
			#else
			if (absolute)
				return Assets.exists(filename, TEXT);

			return Assets.exists(Paths.getPath(filename, TEXT));
			#end
		});
		impl("saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try
			{
				#if MODS_ALLOWED
				if (!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
				File.saveContent(path, content);

				return true;
			}
			catch (e:Dynamic)
			{
				ImplementUtils.addTextToDebug("saveFile: Error trying to save " + path + ": " + e, FlxColor.RED);
			}
			return false;
		});
		impl("deleteFile", function(path:String, ?ignoreModFolders:Bool = false, ?absolute:Bool = false)
		{
			try
			{
				var lePath:String = path;
				if (!absolute)
					lePath = Paths.getPath(path, TEXT, !ignoreModFolders);
				if (FileSystem.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			}
			catch (e:Dynamic)
			{
				ImplementUtils.addTextToDebug("deleteFile: Error trying to delete " + path + ": " + e, FlxColor.RED);
			}
			return false;
		});
		impl("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		impl("directoryFileList", function(folder:String)
		{
			var list:Array<String> = [];
			#if sys
			if (FileSystem.exists(folder))
			{
				for (folder in FileSystem.readDirectory(folder))
				{
					if (!list.contains(folder))
					{
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		// String tools
		impl("stringStartsWith", function(str:String, start:String)
		{
			return str.startsWith(start);
		});
		impl("stringEndsWith", function(str:String, end:String)
		{
			return str.endsWith(end);
		});
		impl("stringSplit", function(str:String, split:String)
		{
			return str.split(split);
		});
		impl("stringTrim", function(str:String)
		{
			return str.trim();
		});

		// Randomization
		impl("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		impl("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		impl("getRandomBool", function(chance:Float = 50)
		{
			return FlxG.random.bool(chance);
		});
	}
}
