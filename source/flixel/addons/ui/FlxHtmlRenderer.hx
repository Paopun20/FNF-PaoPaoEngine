package flixel.addons.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

typedef CheckboxData =
{
	var group:FlxGroup;
	var box:FlxSprite;
	var check:FlxSprite;
	var id:String;
	var checked:Bool;
}

typedef SliderData =
{
	var group:FlxGroup;
	var bg:FlxSprite;
	var fill:FlxSprite;
	var valueText:FlxText;
	var id:String;
	var min:Float;
	var max:Float;
	var value:Float;
}

class FlxHtmlRenderer extends FlxGroup
{
	private var currentY:Float = 10;
	private var padding:Float = 10;
	private var itemHeight:Float = 25;

	// State tracking
	private var checkboxes:Map<String, CheckboxData> = new Map();
	private var sliders:Map<String, SliderData> = new Map();
	private var draggingSlider:SliderData = null;

	// Callbacks
	public var onButtonClick:String->Void = (_) -> {};
	public var onCheckboxChange:String->Bool->Void = (_, _) -> {};
	public var onSliderChange:String->Float->Void = (_, _) -> {};

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		handleInput();
	}

	private function handleInput():Void
	{
		// Handle checkbox clicks
		if (FlxG.mouse.justPressed)
		{
			for (id in checkboxes.keys())
			{
				var cb = checkboxes.get(id);
				if (FlxG.mouse.overlaps(cb.box))
				{
					toggleCheckbox(id);
					break;
				}
			}

			// Check if clicking on any slider
			for (id in sliders.keys())
			{
				var sld = sliders.get(id);
				if (FlxG.mouse.overlaps(sld.bg))
				{
					draggingSlider = sld;
					updateSliderFromMouse(sld);
					break;
				}
			}
		}

		// Handle slider dragging
		if (FlxG.mouse.pressed && draggingSlider != null)
		{
			updateSliderFromMouse(draggingSlider);
		}

		if (FlxG.mouse.justReleased)
		{
			draggingSlider = null;
		}
	}

	private function updateSliderFromMouse(sld:SliderData):Void
	{
		var localX = FlxG.mouse.x - sld.bg.x;
		var percent = FlxMath.bound(localX / sld.bg.width, 0, 1);
		var newValue = sld.min + (sld.max - sld.min) * percent;

		// Round to 2 decimal places
		newValue = Math.round(newValue * 100) / 100;

		if (newValue != sld.value)
		{
			sld.value = newValue;
			sld.fill.makeGraphic(Std.int(sld.bg.width * percent), 10, FlxColor.CYAN);
			sld.valueText.text = Std.string(newValue);
			onSliderChange(sld.id, newValue);
		}
	}

	public function toggleCheckbox(id:String):Void
	{
		var cb = checkboxes.get(id);
		if (cb == null)
			return;

		cb.checked = !cb.checked;

		if (cb.checked)
		{
			if (cb.check == null)
			{
				cb.check = new FlxSprite(cb.box.x + 5, cb.box.y + 5);
				cb.check.makeGraphic(10, 10, FlxColor.GREEN);
				cb.group.add(cb.check);
			}
			cb.check.visible = true;
		}
		else
		{
			if (cb.check != null)
				cb.check.visible = false;
		}

		onCheckboxChange(id, cb.checked);
	}

	public function setCheckbox(id:String, value:Bool):Void
	{
		var cb = checkboxes.get(id);
		if (cb == null || cb.checked == value)
			return;
		toggleCheckbox(id);
	}

	public function getCheckbox(id:String):Bool
	{
		var cb = checkboxes.get(id);
		return cb != null ? cb.checked : false;
	}

	public function setSlider(id:String, value:Float):Void
	{
		var sld = sliders.get(id);
		if (sld == null)
			return;

		sld.value = FlxMath.bound(value, sld.min, sld.max);
		var percent = (sld.value - sld.min) / (sld.max - sld.min);
		sld.fill.makeGraphic(Std.int(sld.bg.width * percent), 10, FlxColor.CYAN);
		sld.valueText.text = Std.string(sld.value);
	}

	public function getSlider(id:String):Float
	{
		var sld = sliders.get(id);
		return sld != null ? sld.value : 0;
	}

	public function render(markup:String):Void
	{
		currentY = padding;
		checkboxes.clear();
		sliders.clear();

		var lines = markup.split('\n');
		var inPanel = false;
		var panelBg:FlxSprite = null;

		for (line in lines)
		{
			line = StringTools.trim(line);
			if (line.length == 0)
				continue;

			if (line.indexOf('<panel') >= 0)
			{
				var title = extractAttribute(line, 'title');
				panelBg = createPanel(title);
				add(panelBg);
				inPanel = true;
				currentY += 35;
			}
			else if (line.indexOf('</panel>') >= 0)
			{
				inPanel = false;
				if (panelBg != null)
				{
					panelBg.makeGraphic(Std.int(FlxG.width - 40), Std.int(currentY + padding), FlxColor.BLACK);
					panelBg.alpha = 0.8;
				}
			}
			else if (line.indexOf('<button') >= 0)
			{
				var id = extractAttribute(line, 'id');
				var text = extractContent(line);
				var btn = createButton(text, id);
				add(btn);
			}
			else if (line.indexOf('<checkbox') >= 0)
			{
				var id = extractAttribute(line, 'id');
				var checked = extractAttribute(line, 'checked') == 'true';
				var text = extractContent(line);
				var chk = createCheckbox(text, id, checked);
				add(chk.group);
			}
			else if (line.indexOf('<slider') >= 0)
			{
				var id = extractAttribute(line, 'id');
				var min = Std.parseFloat(extractAttribute(line, 'min'));
				var max = Std.parseFloat(extractAttribute(line, 'max'));
				var value = Std.parseFloat(extractAttribute(line, 'value'));
				var text = extractContent(line);
				var sld = createSlider(text, id, min, max, value);
				add(sld.group);
			}
			else if (line.indexOf('<text>') >= 0)
			{
				var content = extractContent(line);
				var txt = createText(content);
				add(txt);
			}
			else if (line.indexOf('<header>') >= 0)
			{
				var content = extractContent(line);
				var hdr = createHeader(content);
				add(hdr);
			}
			else if (line.indexOf('<divider') >= 0)
			{
				var div = createDivider();
				add(div);
			}
		}
	}

	private function createPanel(title:String):FlxSprite
	{
		var panel = new FlxSprite(20, currentY);
		panel.makeGraphic(Std.int(FlxG.width - 40), 100, FlxColor.BLACK);
		panel.alpha = 0.8;

		var titleText = new FlxText(30, currentY + 10, FlxG.width - 60, title);
		titleText.setFormat(null, 16, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
		add(titleText);

		return panel;
	}

	private function createButton(text:String, id:String):FlxButton
	{
		var btn = new FlxButton(30, currentY, text, function()
		{
			onButtonClick(id);
		});
		btn.label.setFormat(null, 12, FlxColor.WHITE, CENTER);
		currentY += itemHeight + 5;
		return btn;
	}

	private function createCheckbox(text:String, id:String, checked:Bool):CheckboxData
	{
		var group = new FlxGroup();

		var box = new FlxSprite(30, currentY);
		box.makeGraphic(20, 20, FlxColor.WHITE);
		group.add(box);

		var check:FlxSprite = null;
		if (checked)
		{
			check = new FlxSprite(35, currentY + 5);
			check.makeGraphic(10, 10, FlxColor.GREEN);
			group.add(check);
		}

		var label = new FlxText(60, currentY + 2, FlxG.width - 90, text);
		label.setFormat(null, 12, FlxColor.WHITE);
		group.add(label);

		var data:CheckboxData = {
			group: group,
			box: box,
			check: check,
			id: id,
			checked: checked
		};

		checkboxes.set(id, data);
		currentY += itemHeight;

		return data;
	}

	private function createSlider(text:String, id:String, min:Float, max:Float, value:Float):SliderData
	{
		var group = new FlxGroup();

		var label = new FlxText(30, currentY, 150, text);
		label.setFormat(null, 12, FlxColor.WHITE);
		group.add(label);

		var sliderBg = new FlxSprite(180, currentY + 5);
		sliderBg.makeGraphic(150, 10, FlxColor.GRAY);
		group.add(sliderBg);

		var percent = (value - min) / (max - min);
		var fillWidth = Std.int(150 * percent);
		var sliderFill = new FlxSprite(180, currentY + 5);
		sliderFill.makeGraphic(fillWidth, 10, FlxColor.CYAN);
		group.add(sliderFill);

		var valueText = new FlxText(340, currentY, 50, Std.string(value));
		valueText.setFormat(null, 12, FlxColor.WHITE);
		group.add(valueText);

		var data:SliderData = {
			group: group,
			bg: sliderBg,
			fill: sliderFill,
			valueText: valueText,
			id: id,
			min: min,
			max: max,
			value: value
		};

		sliders.set(id, data);
		currentY += itemHeight;

		return data;
	}

	private function createText(content:String):FlxText
	{
		var txt = new FlxText(30, currentY, FlxG.width - 60, content);
		txt.setFormat(null, 12, FlxColor.WHITE);
		currentY += 20;
		return txt;
	}

	private function createHeader(content:String):FlxText
	{
		currentY += 10;
		var hdr = new FlxText(30, currentY, FlxG.width - 60, content);
		hdr.setFormat(null, 14, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
		currentY += 25;
		return hdr;
	}

	private function createDivider():FlxSprite
	{
		currentY += 5;
		var div = new FlxSprite(30, currentY);
		div.makeGraphic(Std.int(FlxG.width - 60), 2, FlxColor.GRAY);
		currentY += 10;
		return div;
	}

	private function extractAttribute(line:String, attr:String):String
	{
		var pattern = '$attr="';
		var start = line.indexOf(pattern);
		if (start < 0)
			return '';
		start += pattern.length;
		var end = line.indexOf('"', start);
		return line.substring(start, end);
	}

	private function extractContent(line:String):String
	{
		var start = line.indexOf('>') + 1;
		var end = line.indexOf('<', start);
		if (end < 0)
			end = line.length;
		return StringTools.trim(line.substring(start, end));
	}
}
