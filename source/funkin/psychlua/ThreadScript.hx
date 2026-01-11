/* ThreadScript is a class that represents a thread script to be executed in a separate thread. */

package funkin.psychlua;

#if sys
import sys.thread.Thread;
import sys.thread.Mutex;
#end
#if LUA_ALLOWED
import funkin.psychlua.FunkinLua as Lua;
#end
#if HSCRIPT_ALLOWED
import funkin.psychlua.HScript;
#end
#if PYTHON_ALLOWED
import funkin.psychlua.Python;
#end

class ThreadScript
{
	private var scriptInstance:Dynamic;
	private var scriptPath:String;
	private var type:String;
	private var thread:Thread;
	private var mutex:Mutex;
	private var initialized:Bool = false;
	private var initError:String = null;

	public function new(script:String, type:String)
	{
		this.scriptPath = script;
		this.type = type;
		this.mutex = new Mutex();
		this.thread = Thread.create(initializeScript);
	}

	private function initializeScript():Void
	{
		var instance:Dynamic = null;
		var error:String = null;

		try
		{
			switch (type)
			{
				#if LUA_ALLOWED
				case "lua":
					instance = new Lua(scriptPath);
				#end
				#if HSCRIPT_ALLOWED
				case "hscript":
					instance = new HScript(null, scriptPath);
				#end
				#if PYTHON_ALLOWED
				case "python":
					instance = new Python(null, scriptPath);
				#end
				default:
					throw "Unsupported script type: " + type;
			}
		}
		catch (e:Dynamic)
		{
			error = "Error initializing script: " + e;
			trace(error);
		}

		// Update shared state with mutex protection
		mutex.acquire();
		this.scriptInstance = instance;
		this.initError = error;
		this.initialized = true;
		mutex.release();
	}

	private function waitForInit():Void
	{
		// Wait for initialization to complete
		while (true)
		{
			mutex.acquire();
			var done = initialized;
			mutex.release();

			if (done)
				break;
			Sys.sleep(0.001); // 1ms sleep to avoid busy waiting
		}
	}

	public function call(name:String, args:Array<Dynamic>):Dynamic
	{
		waitForInit();

		mutex.acquire();
		var result:Dynamic = null;
		if (scriptInstance != null)
		{
			try
			{
				result = scriptInstance.call(name, args);
			}
			catch (e:Dynamic)
			{
				trace("Error calling script function '" + name + "': " + e);
			}
		}
		mutex.release();

		return result;
	}

	public function exists(name:String):Bool
	{
		waitForInit();

		mutex.acquire();
		var result:Bool = false;
		if (scriptInstance != null)
		{
			try
			{
				result = scriptInstance.exists(name);
			}
			catch (e:Dynamic)
			{
				trace("Error checking if '" + name + "' exists: " + e);
			}
		}
		mutex.release();

		return result;
	}

	public function get(name:String):Dynamic
	{
		waitForInit();

		mutex.acquire();
		var result:Dynamic = null;
		if (scriptInstance != null)
		{
			try
			{
				result = scriptInstance.get(name);
			}
			catch (e:Dynamic)
			{
				trace("Error getting script value '" + name + "': " + e);
			}
		}
		mutex.release();

		return result;
	}

	public function set(name:String, value:Dynamic):Void
	{
		waitForInit();

		mutex.acquire();
		if (scriptInstance != null)
		{
			try
			{
				scriptInstance.set(name, value);
			}
			catch (e:Dynamic)
			{
				trace("Error setting script value '" + name + "': " + e);
			}
		}
		mutex.release();
	}

	public function isReady():Bool
	{
		mutex.acquire();
		var ready = initialized && scriptInstance != null;
		mutex.release();
		return ready;
	}

	public function getInitError():String
	{
		mutex.acquire();
		var error = initError;
		mutex.release();
		return error;
	}

	public function destroy():Void
	{
		waitForInit(); // Make sure initialization is complete

		mutex.acquire();
		if (scriptInstance != null)
		{
			try
			{
				scriptInstance.destroy();
			}
			catch (e:Dynamic)
			{
				trace("Error destroying script: " + e);
			}
			scriptInstance = null;
		}
		mutex.release();
	}
}
