package funkin.modding.editable;

#if MODS_ALLOWED
import funkin.modding.scripts.Script;
import funkin.modding.scripts.ScriptPack;
#if LUA_ALLOWED
import funkin.modding.scripts.LuaScript;
#end
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if NXSCRIPT_ALLOWED
import funkin.modding.scripts.NxScript;
#end
import funkin.modding.scripts.utils.LuaUtils;
#end

enum EditableType {
	State;
	Substate;
}

class EditableCore {
	public var stateName:String;
	public var stateType:EditableType;
	public var parent:Dynamic;
	public var scripts:ScriptPack;

	public function new(stateName:String, stateType:EditableType, parent:Dynamic):Void {
		this.stateName = stateName;
		this.stateType = stateType;
		this.parent = parent;
		this.scripts = new ScriptPack(stateName);
	}

	public function presetScript(script:Dynamic):Void {
		#if MODS_ALLOWED
		if (script != null && Reflect.hasField(script, 'set')) {
			script.set("stateName", stateName);
			switch (stateType) {
				case EditableType.State:
					script.set("stateType", "State");
					return;
				case EditableType.Substate:
					script.set("stateType", "Substate");
					return;
				default:
					script.set("stateType", "Unknown");
					return;
			}
		}
		#end
	}

	#if MODS_ALLOWED
	public function initScript(script:Script):Void {
		if (script != null) {
			presetScript(script);
			scripts.add(script);
			script.execute();
			CoolLog.info('initialized script: ${script.fileName}');
		}
	}

	#if LUA_ALLOWED
	public function initLua(file:String):Void {
		var script = new LuaScript(file);
		initScript(script);
	}
	#end

	#if HSCRIPT_ALLOWED
	public function initHScript(file:String):Void {
		var script = new HScript(file);
		script.parent = this;
		initScript(script);
	}
	#end

	#if PYTHON_ALLOWED
	public function initPython(file:String):Void {
		var script = new Python(file);
		initScript(script);
	}
	#end

	#if NXSCRIPT_ALLOWED
	public function initNxScript(file:String):Void {
		var script = new NxScript(file);
		initScript(script);
	}
	#end
	#end
	private function getScriptCount():Int {
		return scripts.length;
	}

	public function initScriptFromDirectory(directory:String, name:String):Void {
		#if MODS_ALLOWED
		CoolLog.info('Loading scripts for state "$stateName" from ${directory}');
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED || PYTHON_ALLOWED || NXSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), directory))
			for (file in FileSystem.readDirectory(folder)) {
				if (file.toLowerCase().split('.')[0] == name.toLowerCase()) {
					#if LUA_ALLOWED
					if (file.toLowerCase().endsWith('.lua'))
						initLua(folder + file);
					#end
					#if HSCRIPT_ALLOWED
					if (file.toLowerCase().endsWith('.hx'))
						initHScript(folder + file);
					#end
					#if PYTHON_ALLOWED
					if (file.toLowerCase().endsWith('.py'))
						initPython(folder + file);
					#end
					#if NXSCRIPT_ALLOWED
					if (file.toLowerCase().endsWith('.nx'))
						initNxScript(folder + file);
					#end
				}
			}
		#end

		CoolLog.info('Done - ${getScriptCount()} script(s) loaded for "$stateName"');
		#end
	}

	public function callScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<Script> = null,
			excludeValues:Array<Dynamic> = null):Dynamic {
		if (args == null)
			args = [];
		if (excludeValues == null)
			excludeValues = [];

		return scripts.call(funcToCall, args, ignoreStops, exclusions, excludeValues);
	}

	public function setScript(id:String, v:Dynamic):Void {
		scripts.set(id, v);
	}

	public function destroy():Void {
		scripts.destroy();
	}
}
