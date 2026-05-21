package funkin.frontend.huds;

#if ACHIEVEMENTS_ALLOWED
import openfl.display.Sprite;
import funkin.objects.AchievementPopup;

class AchievementsOverlay extends Sprite {
	public function new() {
		super();
	}

	public function showPopup(popup:AchievementPopup):Void {
		addChild(popup);
	}
}
#end