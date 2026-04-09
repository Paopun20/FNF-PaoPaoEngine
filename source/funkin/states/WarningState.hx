package funkin.states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;

typedef Setting =
{
	name:String,
	value:Bool
}

class WarningState extends EditableState
{
	public static var leftState:Bool = false;

	var settings:Array<Setting>;
	var curSelected:Int = 0;

	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;

	var buttons:Array<Array<FlxText>> = [];

	override function create()
	{
		super.create();

		settings = [{name: "Flashing Lights", value: true}, {name: "Shaders", value: true}];

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		texts = new FlxTypedSpriteGroup<FlxText>();
		texts.alpha = 0.0;
		add(texts);

		var warnText:FlxText = new FlxText(0, 0, FlxG.width,
			"WARNING: This game/some mods contain:
			flashing lights/shaders that may cause seizures
			Please turn them off if you are sensitive to these effects or have epilepsy
			(You can change these settings later in the options menu)
			");
		warnText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		warnText.screenCenter(X);
		warnText.y = 120;
		texts.add(warnText);

		for (i in 0...settings.length)
		{
			var yPos = warnText.y + 230 + (i * 60);

			var label = new FlxText(0, yPos, 0, '[ ${settings[i].name} ]:');
			label.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
			label.x = 50;
			texts.add(label);

			var yes = new FlxText(0, yPos, 0, "YES");
			var no = new FlxText(0, yPos, 0, "NO");

			yes.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			no.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);

			yes.x = 500;
			no.x = 600;

			buttons.push([yes, no]);

			texts.add(yes);
			texts.add(no);
		}

		FlxTween.tween(texts, {alpha: 1.0}, 0.5, {
			onComplete: (_) -> updateItems()
		});
	}

	var index:Array<Int> = [0, 0];

	override function update(elapsed:Float)
	{
		if (leftState)
		{
			super.update(elapsed);
			return;
		}

		var back:Bool = controls.BACK;

		if (controls.UI_UP_P)
			index[1] = -1;
		if (controls.UI_DOWN_P)
			index[1] = 1;
		if (controls.UI_LEFT_P)
			index[0] = -1;
		if (controls.UI_RIGHT_P)
			index[0] = 1;

		if (index[1] != 0)
		{
			curSelected += index[1];
			curSelected = FlxMath.wrap(curSelected, 0, settings.length - 1);
			index[1] = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateItems();
		}

		if (index[0] != 0)
		{
			settings[curSelected].value = !settings[curSelected].value;
			index[0] = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateItems();
		}

		if (controls.ACCEPT || back)
		{
			leftState = true;

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			if (!back)
			{
				ClientPrefs.data.flashing = !settings[0].value;
				ClientPrefs.data.shaders = settings[1].value;

				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));

				MusicBeatState.switchState(new TitleState());
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
		}

		super.update(elapsed);
	}

	function updateItems()
	{
		for (i in 0...settings.length)
		{
			var yes = buttons[i][0];
			var no = buttons[i][1];

			var val = settings[i].value;

			yes.alpha = val ? 1.0 : 0.6;
			no.alpha = val ? 0.6 : 1.0;

			var color = (i == curSelected) ? FlxColor.YELLOW : FlxColor.WHITE;

			yes.color = color;
			no.color = color;
		}
	}
}
