package funkin.backend;

import haxe.ds.StringMap;
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua as Lua;
#end

class EditableState extends MusicBeatState
{
	private var stateName:String;
	private var statePath:String;
	private var script:Array<Dynamic>;

	override public function create():Void
	{
		stateName = Type.getClassName(Type.getClass(this));
		#if MODS_ALLOWED
		statePath = Paths.modFolders(stateName);
		#else
		statePath = Paths.getSharedPath("state/" + stateName);
		#end

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	override public function beatHit():Void
	{
		super.beatHit();
	}

	override public function stepHit():Void
	{
		super.stepHit();
	}

	override public function sectionHit():Void
	{
		super.sectionHit();
	}
}
