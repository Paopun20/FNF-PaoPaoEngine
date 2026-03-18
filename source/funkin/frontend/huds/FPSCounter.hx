package funkin.frontend.huds;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;
#if hxhardware
import hxhardware.CPU;
import hxhardware.GPU;
import hxhardware.Memory;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	private var _color:Int;

	#if hxhardware
	private var cpuUsage:Float = 0;
	private var ramUsage:Float = 0;
	private var gpuUsage:Float = 0;
	#end

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;
		this._color = color;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];
	}

	var deltaTimeout:Float = 0.0;
	var deltaSysTO:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();

		deltaTimeout += deltaTime;
		deltaSysTO += deltaTime;

		if (deltaSysTO >= 500)
		{
			#if hxhardware
			cpuUsage = CPU.getProcessCPUUsage();
			ramUsage = Memory.getProcessPhysicalMemoryUsage();
			gpuUsage = GPU.getSystemTotalGPUUsage();
			#end

			deltaSysTO = 0;
		}

		if (deltaTimeout < 50)
			return;

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;

		updateText();
		deltaTimeout = 0;
	}

	private function format2(v:Float):String
	{
		var rounded = Math.round(v * 100) / 100;
		var s = Std.string(rounded);

		if (s.indexOf('.') == -1)
			return s + ".00";

		var parts = s.split('.');
		if (parts[1].length == 1)
			return s + "0";

		return s;
	}

	public dynamic function updateText():Void
	{ // so people can override it in hscript
		text = 'FPS: ${currentFPS}\n';

		#if hxhardware
		text += '\nCPU: ' + format2(cpuUsage) + '%';
		text += '\nRAM: ' + format2(ramUsage / (1024 * 1024)) + ' MB';
		text += '\nGPU: ' + format2(gpuUsage) + '%';
		#else
		text += '\nMemory: ${FlxStringUtil.formatBytes(memoryMegas)}';
		#end

		textColor = this._color;

		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
	}

	inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif hl
		return hl.Gc.stats().currentMemory;
		#elseif sys
		return cast(openfl.system.System.totalMemory, Float);
		#else
		return cast(openfl.system.System.totalMemory, Float);
		#end
	}
}
