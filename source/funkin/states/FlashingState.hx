package funkin.states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var isYes:Bool = true;
	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;
	var buttons:Array<FlxText> = [];

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		texts = new FlxTypedSpriteGroup<FlxText>();
		texts.alpha = 0.0;
		add(texts);

		var text:String = "Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Do you wish to disable them?";

		var warnText:FlxText = new FlxText(0, 0, FlxG.width, text);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		texts.add(warnText);

		final buttonLabels = ["Yes", "No"];
		final buttonSpacing = 160;
		final startX = (FlxG.width - buttonSpacing) / 2;

		for (i in 0...buttonLabels.length)
		{
			var button = new FlxText(0, 0, 0, buttonLabels[i]);
			button.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			button.y = warnText.y + warnText.height + 24;
			button.x = startX + (i * buttonSpacing);
			buttons.push(button);
			texts.add(button);
		}

		FlxTween.tween(texts, {alpha: 1.0}, 0.5, {
			onComplete: (_) -> updateItems()
		});
	}

	override function update(elapsed:Float)
	{
		if (leftState)
		{
			super.update(elapsed);
			return;
		}

		var back:Bool = controls.BACK;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
			isYes = !isYes;
			updateItems();
		}

		if (controls.ACCEPT || back)
		{
			leftState = true;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			if (!back)
			{
				ClientPrefs.data.flashing = !isYes;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));

				final selectedButton = buttons[isYes ? 0 : 1];
				FlxFlicker.flicker(selectedButton, 1, 0.1, false, true, function(flk:FlxFlicker)
				{
					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						FlxTween.tween(texts, {alpha: 0}, 0.2, {
							onComplete: (_) -> MusicBeatState.switchState(new TitleState())
						});
					});
				});
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(texts, {alpha: 0}, 1, {
					onComplete: (_) -> MusicBeatState.switchState(new TitleState())
				});
			}
		}

		super.update(elapsed);
	}

	function updateItems()
	{
		buttons[0].alpha = isYes ? 1.0 : 0.6;
		buttons[1].alpha = isYes ? 0.6 : 1.0;
	}
}
