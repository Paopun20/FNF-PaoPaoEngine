package funkin.backend.utils;

import flixel.FlxG;

@:cppFileCode('
#include <windows.h>
#include <dwmapi.h>
#pragma comment(lib, "Dwmapi")
')
class FlxWindowUtil {
	public static var isTransparent:Bool = false;

	static var lastBgColor:Int;
	static var lastBorderless:Bool;
	static var lastBgAttr:Dynamic;

	static public function setTransparency(val:Bool):Void {
		if (val == isTransparent)
			return;
		isTransparent = val;
		if (isTransparent) {
			// backup
			lastBgColor = FlxG.camera.bgColor;
			lastBorderless = FlxG.stage.window.borderless;
			@:privateAccess
			lastBgAttr = FlxG.stage.window.context.attributes.background;

			FlxG.camera.bgColor = 0x00000000;
			FlxG.stage.window.borderless = true;
			@:privateAccess
			FlxG.stage.window.context.attributes.background = null;
			_enableTransparency();
		} else {
			FlxG.camera.bgColor = lastBgColor;
			FlxG.stage.window.borderless = lastBorderless;
			@:privateAccess
			FlxG.stage.window.context.attributes.background = lastBgAttr;
			_disableTransparency();
		}
	}

	@:functionCode('
		HWND hWnd = GetActiveWindow();
		SetWindowLong(hWnd, GWL_EXSTYLE,
			GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
		SetLayeredWindowAttributes(hWnd, 0, 255, LWA_ALPHA);
		MARGINS margins = {-1, -1, -1, -1};
		DwmExtendFrameIntoClientArea(hWnd, &margins);
	')
	static private function _enableTransparency():Void {}

	@:functionCode('
		HWND hWnd = GetActiveWindow();
		SetWindowLong(hWnd, GWL_EXSTYLE,
			GetWindowLong(hWnd, GWL_EXSTYLE) & ~WS_EX_LAYERED);
		MARGINS margins = {0, 0, 0, 0};
		DwmExtendFrameIntoClientArea(hWnd, &margins);
	')
	static private function _disableTransparency():Void {}
}
