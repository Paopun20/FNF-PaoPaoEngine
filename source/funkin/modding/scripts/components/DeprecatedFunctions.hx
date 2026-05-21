package funkin.modding.scripts.components;

//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//
import funkin.modding.scripts.utils.LuaUtils;
import funkin.modding.objects.ModchartSprite;

class DeprecatedFunctions {
	public static function implement(funk:Dynamic) {

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		funk.set("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			CoolLog.warning("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead");
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		funk.set("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			CoolLog.warning("objectPlayAnimation is deprecated! Use playAnim instead");
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
		funk.set("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			CoolLog.warning("characterPlayAnim is deprecated! Use playAnim instead");
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
		funk.set("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			CoolLog.warning("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead");
			if (MusicBeatState.getVariables().exists(tag))
				MusicBeatState.getVariables().get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		funk.set("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			CoolLog.warning("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead");
			if (MusicBeatState.getVariables().exists(tag)) {
				var cock:ModchartSprite = MusicBeatState.getVariables().get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		funk.set("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			CoolLog.warning("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead");
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
		funk.set("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			CoolLog.warning("luaSpritePlayAnimation is deprecated! Use playAnim instead");
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).animation.play(name, forced);
			}
		});
		funk.set("setLuaSpriteCamera", function(tag:String, camera:String = '') {
			CoolLog.warning("setLuaSpriteCamera is deprecated! Use setObjectCamera instead");
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			CoolLog.warning("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		funk.set("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			CoolLog.warning("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead");
			if (MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		funk.set("scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			CoolLog.warning("scaleLuaSprite is deprecated! Use scaleObject instead");
			if (MusicBeatState.getVariables().exists(tag)) {
				var shit:ModchartSprite = MusicBeatState.getVariables().get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		funk.set("getPropertyLuaSprite", function(tag:String, variable:String) {
			CoolLog.warning("getPropertyLuaSprite is deprecated! Use getProperty instead");
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
		funk.set("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			CoolLog.warning("setPropertyLuaSprite is deprecated! Use setProperty instead");
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
			CoolLog.warning("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		funk.set("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			CoolLog.warning('musicFadeIn is deprecated! Use soundFadeIn instead.');
		});
		funk.set("musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			CoolLog.warning('musicFadeOut is deprecated! Use soundFadeOut instead.');
		});
		funk.set("updateHitboxFromGroup", function(group:String, index:Int) {
			if (Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			CoolLog.warning('updateHitboxFromGroup is deprecated! Use updateHitbox instead.');
		});
	}
}
