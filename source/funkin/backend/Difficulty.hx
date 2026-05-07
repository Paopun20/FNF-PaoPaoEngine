package funkin.backend;

class Difficulty {
	public static final defaultList:Array<String> = ['Easy', 'Normal', 'Hard'];
	private static final defaultDifficulty:String = 'Normal'; // The chart that has no postfix and starting difficulty on Freeplay/Story Mode

	public static var list:Array<String> = [];

	inline public static function getFilePath(num:Null<Int> = null) {
		if (num == null)
			num = PlayState.storyDifficulty;

		var filePostfix:String = list[num];
		if (filePostfix != null && Paths.formatToSongPath(filePostfix) != Paths.formatToSongPath(defaultDifficulty))
			filePostfix = '-' + filePostfix;
		else
			filePostfix = '';
		return Paths.formatToSongPath(filePostfix);
	}

	inline public static function loadFromWeek(week:WeekData = null) {
		if (week == null)
			week = WeekData.getCurrentWeek();

		var diffStr:String = week.difficulties;
		if (diffStr != null && diffStr.length > 0) {
			var diffs:Array<String> = [];
			for (entry in diffStr.split(',')) {
				if (entry == null)
					continue;

				var trimmedEntry:String = entry.trim();
				if (trimmedEntry.length > 0)
					diffs.push(trimmedEntry);
			}

			if (diffs.length > 0)
				list = diffs;
			else
				resetList();
		} else
			resetList();
	}

	inline public static function resetList() {
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>) {
		list = diffs.copy();
	}

	inline public static function getString(?num:Null<Int> = null, ?canTranslate:Bool = true):String {
		var diffName:String = list[num == null ? PlayState.storyDifficulty : num];
		if (diffName == null)
			diffName = defaultDifficulty;
		return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
	}

	inline public static function getDefault():String {
		return defaultDifficulty;
	}
}
