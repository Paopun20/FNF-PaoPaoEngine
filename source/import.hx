#if !macro
// Discord API
#if DISCORD_ALLOWED
import funkin.api.Discord;
#end
// Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end
#if ACHIEVEMENTS_ALLOWED
import funkin.backend.Achievements;
#end
#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end
import funkin.backend.Paths;
import funkin.backend.Controls;
import funkin.backend.CoolUtil;
import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.modding.editable.EditableState;
import funkin.modding.editable.EditableSubstate;
import funkin.frontend.transition.CustomFadeTransition as CustomFadeTransition; // I remove name it for one go
import funkin.frontend.transition.BaseTransition;
import funkin.backend.ClientPrefs;
import funkin.backend.Conductor;
import funkin.backend.BaseStage;
import funkin.backend.Difficulty;
import funkin.backend.Mods;
import funkin.backend.Language;
import funkin.frontend.ui.*; // Psych-UI
import funkin.objects.Alphabet;
import funkin.objects.BGSprite;
import funkin.states.PlayState;
import funkin.states.LoadingState;
#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end
// Flixel
import flixel.sound.FlxSound;
import flixel.sound.FlxStreamSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

import funkin.utils.CoolLog;
#end
