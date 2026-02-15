package funkin.modding.editable;

import funkin.modding.editable.EditableCore;

class EditableSubstate extends MusicBeatSubstate
{
	private var scripts:EditableCore;

	override public function create():Void
	{
		var stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
		scripts = new EditableCore(stateName, EditableType.Substate);
		scripts.initScriptFromDirectory("scripts/substates/", stateName);
		scripts.setScript("stateName", stateName);
		super.create();
		scripts.callScripts("onCreatePost", []);
	}

	override public function update(elapsed:Float):Void
	{
		scripts.callScripts("onUpdate", [elapsed]);
		super.update(elapsed);
		scripts.callScripts("onUpdatePost", [elapsed]);
	}

	override public function beatHit():Void
	{
		super.beatHit();
		scripts.callScripts("onBeatHit", []);
	}

	override public function stepHit():Void
	{
		super.stepHit();
		scripts.callScripts("onStepHit", []);
	}

	override public function sectionHit():Void
	{
		super.sectionHit();
		scripts.callScripts("onSectionHit", []);
	}

	override public function onFocus():Void
	{
		super.onFocus();
		scripts.callScripts("onFocus", []);
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		scripts.callScripts("onFocusLost", []);
	}

	override public function destroy():Void
	{
		super.destroy();
		scripts.callScripts("onDestroy", []);
		scripts.destroy();
	}
}