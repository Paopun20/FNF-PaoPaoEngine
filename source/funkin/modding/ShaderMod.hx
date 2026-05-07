package funkin.modding;

import funkin.shaders.CustomShader;

class ShaderMod {
	#if (MODS_ALLOWED && !flash && sys)
	public static var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public static function initLuaShader(name:String, ?glslVersion:Int = 120) {
		if (!ClientPrefs.data.shaders)
			return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name)) {
			CoolLog.info('Shader $name already loaded!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck) {
			if (FileSystem.exists(folder)) {
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag)) {
					frag = File.getContent(frag);
					found = true;
				} else
					frag = null;

				if (FileSystem.exists(vert)) {
					vert = File.getContent(vert);
					found = true;
				} else
					vert = null;

				if (found) {
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		CoolLog.warning('Shader $name not found in any mods folder!');
		#else
		CoolLog.warning('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
}
