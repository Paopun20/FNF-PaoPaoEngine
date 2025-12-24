package options;

import objects.AttachedText;
import objects.CheckboxThingie;
import options.Option.OptionType;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var optionsArray:Array<GameplayOption> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var curOption(get, never):GameplayOption;

	inline function get_curOption()
		return optionsArray[curSelected];

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	public function new()
	{
		super();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		grpTexts = new FlxTypedGroup<AttachedText>();
		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();

		add(grpOptions);
		add(grpTexts);
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var opt = optionsArray[i];

			var optionText = new Alphabet(150, 360, opt.name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (opt.type == BOOL)
			{
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();

				var checkbox = new CheckboxThingie(optionText.x - 105, optionText.y, opt.getValue());
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();

				var valueText = new AttachedText(Std.string(opt.getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;

				grpTexts.add(valueText);
				opt.setChild(valueText);
			}

			updateTextFrom(opt);
		}

		changeSelection();
		reloadCheckboxes();
	}

	function getOptions()
	{
		optionsArray.push(new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ['multiplicative', 'constant']));

		var scrollSpeed = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		scrollSpeed.minValue = 0.01;
		scrollSpeed.maxValue = 1000;
		scrollSpeed.changeValue = 0.05;
		scrollSpeed.scrollSpeed = 2;
		scrollSpeed.decimals = 2;
		scrollSpeed.displayFormat = '%vX';
		optionsArray.push(scrollSpeed);

		#if FLX_PITCH
		var songSpeed = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		songSpeed.minValue = 0.5;
		songSpeed.maxValue = 1000;
		songSpeed.changeValue = 0.05;
		songSpeed.decimals = 2;
		songSpeed.displayFormat = '%vX';
		optionsArray.push(songSpeed);
		#end

		var hg = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		hg.minValue = 0;
		hg.maxValue = 1000;
		hg.changeValue = 0.1;
		hg.displayFormat = '%vX';
		optionsArray.push(hg);

		var hl = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		hl.minValue = 0;
		hl.maxValue = 1000;
		hl.changeValue = 0.1;
		hl.displayFormat = '%vX';
		optionsArray.push(hl);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false));
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		if (nextAccept <= 0)
		{
			if (curOption.type == BOOL)
			{
				if (controls.ACCEPT)
				{
					curOption.setValue(!curOption.getValue());
					curOption.change();
					reloadCheckboxes();
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
			else
			{
				handleValueInput(elapsed);
			}

			if (controls.RESET)
				resetAll();
		}

		if (nextAccept > 0)
			nextAccept--;
		super.update(elapsed);
	}

	function handleValueInput(elapsed:Float)
	{
		if (!(controls.UI_LEFT || controls.UI_RIGHT))
		{
			clearHold();
			return;
		}

		var pressed = controls.UI_LEFT_P || controls.UI_RIGHT_P;
		var dir = controls.UI_LEFT ? -1 : 1;

		if (pressed)
			holdValue = curOption.getValue();

		if (pressed || holdTime > 0.5)
		{
			switch (curOption.type)
			{
				case INT, FLOAT, PERCENT:
					holdValue += (pressed ? curOption.changeValue : curOption.scrollSpeed * elapsed) * dir;
					holdValue = FlxMath.bound(holdValue, curOption.minValue, curOption.maxValue);
					curOption.setValue(curOption.type == INT ? Math.round(holdValue) : FlxMath.roundDecimal(holdValue, curOption.decimals));

				case STRING:
					if (pressed)
					{
						curOption.curOption = FlxMath.wrap(curOption.curOption + dir, 0, curOption.options.length - 1);
						curOption.setValue(curOption.options[curOption.curOption]);
					}

				default:
			}

			updateTextFrom(curOption);
			curOption.change();
			if (pressed)
				FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		holdTime += elapsed;
	}

	function resetAll()
	{
		for (opt in optionsArray)
		{
			opt.setValue(opt.defaultValue);
			if (opt.type == STRING)
				opt.curOption = opt.options.indexOf(opt.defaultValue);
			updateTextFrom(opt);
			opt.change();
		}
		reloadCheckboxes();
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function updateTextFrom(option:GameplayOption)
	{
		var val:Dynamic = option.getValue();
		if (option.type == PERCENT)
			val *= 100;
		option.text = option.displayFormat.replace('%v', Std.string(val));
	}

	function clearHold()
	{
		holdTime = 0;
		holdValue = curOption.getValue();
	}

	function changeSelection(change:Int = 0)
	{
		clearHold();
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		for (i => item in grpOptions.members)
		{
			item.targetY = i - curSelected;
			item.alpha = item.targetY == 0 ? 1 : 0.6;
		}

		for (text in grpTexts)
			text.alpha = (text.ID == curSelected) ? 1 : 0.6;

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.daValue = optionsArray[checkbox.ID].getValue();
	}
}

class GameplayOption
{
	private var child:Alphabet;

	public var text(get, set):String;
	public var onChange:Void->Void = null; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; // Variable from ClientPrefs.hx's gameplaySettings

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; // Don't change this
	public var options:Array<String> = null; // Only used in string type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; // Only used in int/float/percent type
	public var maxValue:Dynamic = null; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type

	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		_name = name;
		this.name = Language.getPhrase('setting_$name', name);
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if (options.length > 0)
						defaultValue = options[0];

				default:
			}
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case STRING:
				var num:Int = options.indexOf(getValue());
				if (num > -1)
					curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
	}

	public function change()
	{
		// nothing lol
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
		return ClientPrefs.data.gameplaySettings.get(variable);

	public function setValue(value:Dynamic)
		ClientPrefs.data.gameplaySettings.set(variable, value);

	public function setChild(child:Alphabet)
		this.child = child;

	var _name:String = null;
	var _text:String = null;

	private function get_text()
		return _text;

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			_text = newValue;
			child.text = Language.getPhrase('setting_$_name-$_text', _text);
			return _text;
		}
		return null;
	}
}
