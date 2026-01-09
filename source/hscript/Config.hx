package hscript;

class Config
{
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"funkin.backend",
		"funkin.shaders",
		"funkin.psychlua",
		"funkin.options",
		"funkin.objects",
		"haxe.ds",
		"haxe.crypto",
		"haxe.io.Bytes",
		"Math",
		"Std",
		"StringTools",
		"Date",
	];
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"funkin.backend",
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack",
		"haxe.ds",
		"haxe.crypto"
	];
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.FlxGame",
		"flixel.addons.ui.FlxUI9SliceSprite",
		"flixel.addons.ui.FlxUIList",
		"flixel.addons.ui.FlxUINumericStepper",
		"Type",
		"Reflect",
		"haxe.macro.Context",
		"haxe.rtti.Rtti"
	];
	public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}
