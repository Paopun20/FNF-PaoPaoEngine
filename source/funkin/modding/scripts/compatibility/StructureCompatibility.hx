package funkin.modding.scripts.compatibility;

import haxe.ds.StringMap;

class StructureCompatibility {
	/**
	 * Compatibility map for Psych Engine 0.6.3 and 0.7.3 - 1.0.4 -> FNF PaoPao Engine
	 * This allows old mods to work without modification by redirecting old class paths to new ones
	 */
	public static final classAliasMap:StringMap<String> = [
		// Psych 0.7.3 - 1.0.4
		// backend
		'backend.Conductor' => 'funkin.backend.Conductor',
		'backend.ClientPrefs' => 'funkin.backend.ClientPrefs',
		'backend.Paths' => 'funkin.backend.Paths',
		'backend.CoolUtil' => 'funkin.backend.CoolUtil',
		'backend.Difficulty' => 'funkin.backend.Difficulty',
		'backend.Mods' => 'funkin.backend.Mods',
		'backend.Highscore' => 'funkin.backend.Highscore',
		'backend.Achievements' => 'funkin.backend.Achievements',
		'backend.MusicBeatState' => 'funkin.backend.MusicBeatState',
		'backend.MusicBeatSubstate' => 'funkin.backend.MusicBeatSubstate',
		'backend.BaseStage' => 'funkin.backend.BaseStage',
		'backend.StageData' => 'funkin.backend.StageData',
		'backend.WeekData' => 'funkin.backend.WeekData',
		'backend.Song' => 'funkin.backend.Song',
		'backend.Rating' => 'funkin.backend.Rating',
		'backend.Controls' => 'funkin.backend.Controls',
		'backend.Discord' => 'funkin.api.Discord',
		'backend.DiscordClient' => 'funkin.api.Discord',
		// psychlua
		'psychlua.LuaUtils' => 'funkin.modding.scripts.utils.LuaUtils',
		'psychlua.CallbackHandler' => 'funkin.modding.scripts.components.CallbackHandler',
		'psychlua.CustomSubstate' => 'funkin.modding.scripts.components.CustomSubstate',
		'psychlua.DeprecatedFunctions' => 'funkin.modding.scripts.components.DeprecatedFunctions',
		'psychlua.ExtraFunctions' => 'funkin.modding.scripts.components.ExtraFunctions',
		'psychlua.FlxAnimateFunctions' => 'funkin.modding.scripts.components.FlxAnimateFunctions',
		'psychlua.ReflectionFunctions' => 'funkin.modding.scripts.components.ReflectionFunctions',
		'psychlua.ShaderFunctions' => 'funkin.modding.scripts.components.ShaderFunctions',
		'psychlua.TextFunctions' => 'funkin.modding.scripts.components.TextFunctions',
		'psychlua.ModchartAnimateSprite' => 'funkin.modding.scripts.components.ModchartAnimateSprite',
		// States
		'states.PlayState' => 'funkin.states.PlayState',
		'states.MainMenuState' => 'funkin.states.MainMenuState',
		'states.FreeplayState' => 'funkin.states.FreeplayState',
		'states.StoryMenuState' => 'funkin.states.StoryMenuState',
		'states.TitleState' => 'funkin.states.TitleState',
		'states.LoadingState' => 'funkin.states.LoadingState',
		'states.CreditsState' => 'funkin.states.CreditsState',
		'states.ModsMenuState' => 'funkin.states.ModsMenuState',
		'states.editors.CharacterEditorState' => 'funkin.modding.editors.CharacterEditorState',
		'states.editors.ChartingState' => 'funkin.modding.editors.ChartingState',
		'states.editors.MasterEditorMenu' => 'funkin.modding.editors.MasterEditorMenu',
		'states.editors.NoteSplashEditorState' => 'funkin.modding.editors.NoteSplashEditorState',
		'states.editors.StageEditorState' => 'funkin.modding.editors.StageEditorState',
		'states.editors.WeekEditorState' => 'funkin.modding.editors.WeekEditorState',
		'states.editors.MenuCharacterEditorState' => 'funkin.modding.editors.MenuCharacterEditorState',
		// Objects
		'objects.Alphabet' => 'funkin.objects.Alphabet',
		'objects.Character' => 'funkin.objects.Character',
		'objects.Note' => 'funkin.objects.Note',
		'objects.NoteSplash' => 'funkin.objects.NoteSplash',
		'objects.StrumNote' => 'funkin.objects.StrumNote',
		'objects.HealthIcon' => 'funkin.objects.HealthIcon',
		'objects.BGSprite' => 'funkin.objects.BGSprite',
		'objects.AttachedSprite' => 'funkin.objects.AttachedSprite',
		'objects.AttachedText' => 'funkin.objects.AttachedText',
		'objects.MenuCharacter' => 'funkin.objects.MenuCharacter',
		// Substates
		'substates.GameOverSubstate' => 'funkin.substates.GameOverSubstate',
		'substates.PauseSubState' => 'funkin.substates.PauseSubState',
		'substates.CustomSubstate' => 'funkin.modding.scripts.components.CustomSubstate',
		'substates.GameplayChangersSubstate' => 'funkin.options.GameplayChangersSubstate',
		// Options
		'options.OptionsState' => 'funkin.options.OptionsState',
		'options.GameplayChangersSubstate' => 'funkin.options.GameplayChangersSubstate',
		'options.NotesColorSubState' => 'funkin.options.NotesColorSubState',
		'options.NoteOffsetState' => 'funkin.options.NoteOffsetState',
		'options.VisualsSettingsSubState' => 'funkin.options.VisualsSettingsSubState',
		'options.GraphicsSettingsSubState' => 'funkin.options.GraphicsSettingsSubState',
		'options.GameplaySettingsSubState' => 'funkin.options.GameplaySettingsSubState',
		// Psych 0.6.3 (no namespace)
		'Conductor' => 'funkin.backend.Conductor',
		'ClientPrefs' => 'funkin.backend.ClientPrefs',
		'Paths' => 'funkin.backend.Paths',
		'CoolUtil' => 'funkin.backend.CoolUtil',
		'Difficulty' => 'funkin.backend.Difficulty',
		'Mods' => 'funkin.backend.Mods',
		'Highscore' => 'funkin.backend.Highscore',
		'Achievements' => 'funkin.backend.Achievements',
		'MusicBeatState' => 'funkin.backend.MusicBeatState',
		'MusicBeatSubstate' => 'funkin.backend.MusicBeatSubstate',
		'BaseStage' => 'funkin.backend.BaseStage',
		'StageData' => 'funkin.backend.StageData',
		'WeekData' => 'funkin.backend.WeekData',
		'Song' => 'funkin.backend.Song',
		'Rating' => 'funkin.backend.Rating',
		'Controls' => 'funkin.backend.Controls',
		'Discord' => 'funkin.api.Discord',
		'DiscordClient' => 'funkin.api.Discord',
		'PlayState' => 'funkin.states.PlayState',
		'MainMenuState' => 'funkin.states.MainMenuState',
		'FreeplayState' => 'funkin.states.FreeplayState',
		'StoryMenuState' => 'funkin.states.StoryMenuState',
		'TitleState' => 'funkin.states.TitleState',
		'LoadingState' => 'funkin.states.LoadingState',
		'CreditsState' => 'funkin.states.CreditsState',
		'ModsMenuState' => 'funkin.states.ModsMenuState',
		'CharacterEditorState' => 'funkin.modding.editors.CharacterEditorState',
		'ChartingState' => 'funkin.modding.editors.ChartingState',
		'MasterEditorMenu' => 'funkin.modding.editors.MasterEditorMenu',
		'NoteSplashEditorState' => 'funkin.modding.editors.NoteSplashEditorState',
		'StageEditorState' => 'funkin.modding.editors.StageEditorState',
		'WeekEditorState' => 'funkin.modding.editors.WeekEditorState',
		'MenuCharacterEditorState' => 'funkin.modding.editors.MenuCharacterEditorState',
		'Alphabet' => 'funkin.objects.Alphabet',
		'Character' => 'funkin.objects.Character',
		'Note' => 'funkin.objects.Note',
		'NoteSplash' => 'funkin.objects.NoteSplash',
		'StrumNote' => 'funkin.objects.StrumNote',
		'HealthIcon' => 'funkin.objects.HealthIcon',
		'BGSprite' => 'funkin.objects.BGSprite',
		'AttachedSprite' => 'funkin.objects.AttachedSprite',
		'AttachedText' => 'funkin.objects.AttachedText',
		'MenuCharacter' => 'funkin.objects.MenuCharacter',
		'GameOverSubstate' => 'funkin.substates.GameOverSubstate',
		'PauseSubState' => 'funkin.substates.PauseSubState',
		'CustomSubstate' => 'funkin.modding.scripts.components.CustomSubstate',
		'GameplayChangersSubstate' => 'funkin.options.GameplayChangersSubstate',
		'OptionsState' => 'funkin.options.OptionsState',
		'NotesColorSubState' => 'funkin.options.NotesColorSubState',
		'NoteOffsetState' => 'funkin.options.NoteOffsetState',
		'VisualsSettingsSubState' => 'funkin.options.VisualsSettingsSubState',
		'GraphicsSettingsSubState' => 'funkin.options.GraphicsSettingsSubState',
		'GameplaySettingsSubState' => 'funkin.options.GameplaySettingsSubState',
	];

	public static function resolveClass(className:String):Class<Dynamic> {
		var myClass:Dynamic = Type.resolveClass(className);
		if (myClass == null && classAliasMap.exists(className)) {
			var newClassName = classAliasMap.get(className);
			myClass = Type.resolveClass(newClassName);

			if (myClass == null) {
				CoolLog.info('[Compatibility] WARNING: Alias "$className" → "$newClassName" exists, but target class not found!');
			}
		} else if (myClass == null) {
			CoolLog.info('[Compatibility] WARNING: Class "$className" not found and no alias exists. This may break old mods.');
			CoolLog.info('[Compatibility] If this is a common class, consider adding it to StructureCompatibility.classAliasMap');
		}

		return myClass;
	}
}
