package funkin.modding.scripts;

/*
    DummyScript is a placeholder script that does nothing. It can be used when you want to have a script reference but don't want it to actually execute any code or have any functionality. All of its methods are overridden to do nothing or return null/false as appropriate.
*/
class DummyScript extends Script implements IScriptExecutor {
    public function new() {
        super("DummyScript:Void");
    }

    override function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
        return null;
    }

    override function execute():Void {}
    override function set(variable:String, value:Dynamic):Void {}
    override function get(variable:String):Dynamic {
        return null;
    }

    override function hasFunction(funcName:String):Bool {
        return false;
    }
}