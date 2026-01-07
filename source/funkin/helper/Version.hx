package funkin.helper;

class Version
{
	private static final PRE_ORDER:Map<String, Int> = [
		"dev" => 0,
		"alpha" => 1,
		"beta" => 2,
		"rc" => 3
	];
	
	public static function isOutdated(current:String, target:String):Bool
	{
		var c = parse(current);
		var t = parse(target);
		
		var len:Int = Std.int(Math.max(c.nums.length, t.nums.length));
		for (i in 0...len)
		{
			var a = i < c.nums.length ? c.nums[i] : 0;
			var b = i < t.nums.length ? t.nums[i] : 0;
			if (a < b) return true;
			if (a > b) return false;
		}
		
		return prereleaseIsOlder(c.pre, t.pre);
	}
	
	private static function prereleaseIsOlder(a:Null<String>, b:Null<String>):Bool
	{
		// release version (no prerelease) is newer than any prerelease
		if (a == null && b != null) return false; // current is release, target is pre → not outdated
		if (a != null && b == null) return true;  // current is pre, target is release → outdated
		if (a == null && b == null) return false; // both are releases → not outdated
		
		// both are prereleases, compare their order
		var pa = PRE_ORDER.get(a);
		var pb = PRE_ORDER.get(b);
		
		// if both are recognized prerelease types
		if (pa != null && pb != null)
			return pa < pb;
		
		// handle unknown prerelease identifiers with lexicographic comparison
		if (pa == null && pb == null)
			return a < b;
		
		// if one is unknown, treat unknown as newer than known prerelease types
		if (pa == null) return false; // unknown current is treated as newer
		return true; // unknown target is treated as newer
	}
	
	private static function parse(v:String)
	{
		var parts = v.split("-");
		return {
			nums: normalize(parts[0]),
			pre: parts.length > 1 ? parts[1].toLowerCase() : null
		};
	}
	
	private static function normalize(v:String):Array<Int>
	{
		return [for (p in v.split(".")) Std.parseInt(p) ?? 0];
	}
}