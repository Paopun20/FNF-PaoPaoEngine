package funkin.states;

import funkin.ds.Geodify;

class NewModsMenuState extends MusicBeatState {
    override function create() {
		FunkinCache.clearStoredMemory();
		FunkinCache.clearUnusedMemory();
        add(new Geodify(0, 0, FlxG.width, FlxG.height));
    }

    override function update(elapsed:Float) {
		super.update(elapsed);
    }
}