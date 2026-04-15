package funkin.modding.scripts.components;

import funkin.modding.scripts.LuaScript;
import funkin.modding.scripts.utils.ImplementUtils;
import funkin.modding.scripts.utils.LuaUtils;
import funkin.shaders.CustomShader;

class ShaderFunctions
{
	public static function initShader(name:String)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		var fragPath = Paths.shaderFragment(name);
		var vertPath = Paths.shaderVertex(name);
		if (!openfl.Assets.exists(fragPath) && !openfl.Assets.exists(vertPath))
		{
			ImplementUtils.addTextToDebug('initLuaShader: Shader "$name" not found!', FlxColor.RED);
			return false;
		}
		return true;
	}

	public static function setSpriteShader(obj:String, shader:String)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		var split:Array<String> = obj.split('.');
		var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
		if (split.length > 1)
			leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);

		if (leObj != null)
		{
			leObj.shader = new CustomShader(shader);
			return true;
		}

		ImplementUtils.addTextToDebug('setSpriteShader: Object "$obj" not found!', FlxColor.RED);
		return false;
	}

	public static function removeSpriteShader(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
			return false;
		}

	#if LUA_ALLOWED
	public static function implement(lua:LuaScript)
	{
		lua.set("initLuaShader", initShader);
		lua.set("setSpriteShader", setSpriteShader);
		lua.set("removeSpriteShader", removeSpriteShader);

		lua.set("getShaderBool", function(obj:String, prop:String) return getUniform(obj, prop));
		lua.set("getShaderBoolArray", function(obj:String, prop:String) return getUniform(obj, prop));
		lua.set("getShaderInt", function(obj:String, prop:String) return getUniform(obj, prop));
		lua.set("getShaderIntArray", function(obj:String, prop:String) return getUniform(obj, prop));
		lua.set("getShaderFloat", function(obj:String, prop:String) return getUniform(obj, prop));
		lua.set("getShaderFloatArray", function(obj:String, prop:String) return getUniform(obj, prop));

		lua.set("setShaderBool", function(obj:String, prop:String, value:Bool) return setUniform(obj, prop, value));
		lua.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) return setUniform(obj, prop, values));
		lua.set("setShaderInt", function(obj:String, prop:String, value:Int) return setUniform(obj, prop, value));
		lua.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) return setUniform(obj, prop, values));
		lua.set("setShaderFloat", function(obj:String, prop:String, value:Float) return setUniform(obj, prop, value));
		lua.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) return setUniform(obj, prop, values));

		lua.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String)
		{
			var shader = getShader(obj);
			if (shader == null)
				return false;

			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				shader.hset(prop, value.bitmap);
				return true;
			}
			return false;
		});
	}
	#end

	#if PYTHON_ALLOWED
	public static function pyimplement(python:Python)
	{
		python.set("initPythonShader", initShader);
		python.set("setSpriteShader", setSpriteShader);
		python.set("removeSpriteShader", removeSpriteShader);

		python.set("getShaderBool", (obj:String, prop:String) -> getUniform(obj, prop));
		python.set("getShaderBoolArray", (obj:String, prop:String) -> getUniform(obj, prop));
		python.set("getShaderInt", (obj:String, prop:String) -> getUniform(obj, prop));
		python.set("getShaderIntArray", (obj:String, prop:String) -> getUniform(obj, prop));
		python.set("getShaderFloat", (obj:String, prop:String) -> getUniform(obj, prop));
		python.set("getShaderFloatArray", (obj:String, prop:String) -> getUniform(obj, prop));

		python.set("setShaderBool", (obj:String, prop:String, value:Bool) -> setUniform(obj, prop, value));
		python.set("setShaderBoolArray", (obj:String, prop:String, values:Dynamic) -> setUniform(obj, prop, values));
		python.set("setShaderInt", (obj:String, prop:String, value:Int) -> setUniform(obj, prop, value));
		python.set("setShaderIntArray", (obj:String, prop:String, values:Dynamic) -> setUniform(obj, prop, values));
		python.set("setShaderFloat", (obj:String, prop:String, value:Float) -> setUniform(obj, prop, value));
		python.set("setShaderFloatArray", (obj:String, prop:String, values:Dynamic) -> setUniform(obj, prop, values));

		python.set("setShaderSampler2D", (obj:String, prop:String, bitmapdataPath:String) ->
		{
			var shader = getShader(obj);
			if (shader == null)
				return false;
			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				shader.hset(prop, value.bitmap);
				return true;
			}
			return false;
		});
	}
	#end

	static function getUniform(obj:String, prop:String):Dynamic
	{
		var shader = getShader(obj);
		if (shader == null)
			return null;
		return shader.hget(prop);
	}

	static function setUniform(obj:String, prop:String, value:Dynamic):Bool
	{
		var shader = getShader(obj);
		if (shader == null)
			return false;
		shader.hset(prop, value);
		return true;
	}

	public static function getShader(obj:String):CustomShader
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
			ImplementUtils.addTextToDebug('Error on getting shader: Object "$obj" not found', FlxColor.RED);
			#else
			CoolLog.error('Error on getting shader: Object "$obj" not found');
			#end
			return null;
		}

		var shader = Std.downcast(target.shader, CustomShader);
		if (shader == null)
			ImplementUtils.addTextToDebug('Error on getting shader: Shader on "$obj" is not a CustomShader', FlxColor.RED);
		return shader;
	}
}
