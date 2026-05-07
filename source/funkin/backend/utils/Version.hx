package funkin.backend.utils;

import thx.semver.Version as SemVer;

class Version {
	public static function isOutdated(current:String, target:String):Bool {
		return (current : SemVer) < (target : SemVer);
	}
}
