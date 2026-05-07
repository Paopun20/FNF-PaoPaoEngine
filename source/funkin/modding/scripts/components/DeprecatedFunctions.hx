package funkin.modding.scripts.components;

//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//
import funkin.modding.scripts.utils.ImplementUtils;
import funkin.modding.scripts.utils.LuaUtils;
import funkin.modding.objects.ModchartSprite;

class DeprecatedFunctions {
	public static function implement(funk:Dynamic) {
		var impl = ImplementUtils.make(funk);

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		impl("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			ImplementUtils.addTextToDebug("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", FlxColor.RED);
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		impl("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			ImplementUtils.addTextToDebug("objectPlayAnimation is deprecated! Use playAnim instead", FlxColor.RED);
			if (PlayState.instance.getLuaObject(obj) != null) {
				PlayState.instance.getLuaObject(obj).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (spr != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		impl("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			ImplementUtils.addTextToDebug("characterPlayAnim is deprecated! Use playAnim instead", FlxColor.RED);
			switch (character.toLowerCase()) {
				case 'dad':
					if (PlayState.instance.dad.hasAnimation(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if (PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if (PlayState.instance.boyfriend.hasAnimation(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		impl("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			ImplementUtils.addTextToDebug("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag))
				MusicBeatState.getVariables().get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		impl("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			ImplementUtils.addTextToDebug("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				var cock:ModchartSprite = MusicBeatState.getVariables().get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		impl("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			ImplementUtils.addTextToDebug("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = MusicBeatState.getVariables().get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		impl("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			ImplementUtils.addTextToDebug("luaSpritePlayAnimation is deprecated! Use playAnim instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).animation.play(name, forced);
			}
		});
		impl("setLuaSpriteCamera", function(tag:String, camera:String = '') {
			ImplementUtils.addTextToDebug("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			ImplementUtils.addTextToDebug("Lua sprite with tag: " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			ImplementUtils.addTextToDebug("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		impl("scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			ImplementUtils.addTextToDebug("scaleLuaSprite is deprecated! Use scaleObject instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				var shit:ModchartSprite = MusicBeatState.getVariables().get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		impl("getPropertyLuaSprite", function(tag:String, variable:String) {
			ImplementUtils.addTextToDebug("getPropertyLuaSprite is deprecated! Use getProperty instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(MusicBeatState.getVariables().get(tag), variable);
			}
			return null;
		});
		impl("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			ImplementUtils.addTextToDebug("setPropertyLuaSprite is deprecated! Use setProperty instead", FlxColor.RED);
			if (MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
					return true;
				}
				Reflect.setProperty(MusicBeatState.getVariables().get(tag), variable, value);
				return true;
			}
			ImplementUtils.addTextToDebug("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!", FlxColor.RED);
			return false;
		});
		impl("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			ImplementUtils.addTextToDebug('musicFadeIn is deprecated! Use soundFadeIn instead.', FlxColor.RED);
		});
		impl("musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			ImplementUtils.addTextToDebug('musicFadeOut is deprecated! Use soundFadeOut instead.', FlxColor.RED);
		});
		impl("updateHitboxFromGroup", function(group:String, index:Int) {
			if (Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			ImplementUtils.addTextToDebug('updateHitboxFromGroup is deprecated! Use updateHitbox instead.', FlxColor.RED);
		});
	}
}
