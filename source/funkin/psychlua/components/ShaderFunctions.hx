package funkin.psychlua.components;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

import funkin.psychlua.ImplementUtils;

class ShaderFunctions
{
    #if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name);
			#else
			ImplementUtils.addTextToDebug("initLuaShader: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				ImplementUtils.addTextToDebug('setSpriteShader: Shader $shader is missing!', FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new funkin.shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shader, arr[0], arr[1]);
				return true;
			}
			#else
			ImplementUtils.addTextToDebug("setSpriteShader: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderBool: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderBool: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderBoolArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderBoolArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderInt: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderInt: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderIntArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderIntArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderFloat: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderFloat: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("getShaderFloatArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			ImplementUtils.addTextToDebug("getShaderFloatArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderBool: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderBool: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderBoolArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderBoolArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderInt: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderInt: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderIntArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderIntArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderFloat: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderFloat: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderFloatArray: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			ImplementUtils.addTextToDebug("setShaderFloatArray: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				ImplementUtils.addTextToDebug("setShaderSampler2D: Shader is not FlxRuntimeShader!", FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			ImplementUtils.addTextToDebug("setShaderSampler2D: Platform unsupported for Runtime Shaders!", FlxColor.RED);
			return false;
			#end
		});
	}
	#end

	#if PYTHON_ALLOWED
	public static function pyimplement(python:Python)
	{
		#if (!flash && MODS_ALLOWED && sys)
		inline function get(obj:String):FlxRuntimeShader
		{
			var shader = getShader(obj);
			if (shader == null)
			{
				Python.pythonTrace("Shader is not FlxRuntimeShader!", FlxColor.RED);
				return null;
			}
			return shader;
		}

		python.set("getShaderBool", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getBool(prop) : null;
		});

		python.set("getShaderBoolArray", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getBoolArray(prop) : null;
		});

		python.set("getShaderInt", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getInt(prop) : null;
		});

		python.set("getShaderIntArray", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getIntArray(prop) : null;
		});

		python.set("getShaderFloat", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getFloat(prop) : null;
		});

		python.set("getShaderFloatArray", (obj:String, prop:String) ->
		{
			var s = get(obj);
			return s != null ? s.getFloatArray(prop) : null;
		});

		python.set("setShaderBool", (obj:String, prop:String, value:Bool) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setBool(prop, value);
			return true;
		});

		python.set("setShaderBoolArray", (obj:String, prop:String, values:Dynamic) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setBoolArray(prop, values);
			return true;
		});

		python.set("setShaderInt", (obj:String, prop:String, value:Int) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setInt(prop, value);
			return true;
		});

		python.set("setShaderIntArray", (obj:String, prop:String, values:Dynamic) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setIntArray(prop, values);
			return true;
		});

		python.set("setShaderFloat", (obj:String, prop:String, value:Float) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setFloat(prop, value);
			return true;
		});

		python.set("setShaderFloatArray", (obj:String, prop:String, values:Dynamic) ->
		{
			var s = get(obj);
			if (s == null)
				return false;
			s.setFloatArray(prop, values);
			return true;
		});

		python.set("setShaderSampler2D", (obj:String, prop:String, bitmapdataPath:String) ->
		{
			var s = get(obj);
			if (s == null)
				return false;

			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				s.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
		});
		#else
		python.pythonTrace("Runtime Shaders unsupported on this platform!", FlxColor.RED);
		#end
	}
	#end

	#if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if (split.length > 1)
			target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
		else
			target = LuaUtils.getObjectDirectly(split[0]);

		if (target == null)
		{
		    #if LUA_ALLOWED
			ImplementUtils.addTextToDebug('Error on getting shader: Object $obj not found', FlxColor.RED);
			return null;
		    #else
			CoolLog.error("Error on getting shader: Object $obj not found");
			return null;
		    #end
		}
		return cast(target.shader, FlxRuntimeShader);
	}
	#end
}
