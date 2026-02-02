#if sys
import sys.thread.Mutex;
#end
import funkin.utils.ThreadUtil;

interface ThreadedInterface
{
	public function set(variable:String, data:Dynamic):Void;
	public function get(variable:String):Dynamic;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic;
	public function stop():Void;
	public function pause():Void;
	public function resume():Void;
}

class ThreadedScript<T> implements ThreadedInterface
{
	var script:T;

	#if (target.threaded)
	var thread:sys.thread.Thread;
	var mutex:Mutex;
	var running:Bool = false;
	var paused:Bool = false;
	#end

	public var scriptName(get, never):String;

	public function new(script:T)
	{
		this.script = script;
		#if (target.threaded)
		mutex = new Mutex();
		#end
	}

	function get_scriptName():String
	{
		return Reflect.field(script, 'scriptName');
	}

	/**
	 * Safely set a variable in the script (thread-safe)
	 */
	public function set(variable:String, data:Dynamic):Void
	{
		#if (target.threaded)
		mutex.acquire();
		try
		{
			Reflect.callMethod(script, Reflect.field(script, 'set'), [variable, data]);
		}
		catch (e)
		{
			trace('Error setting variable: ${e.details()}');
		}
		mutex.release();
		#else
		Reflect.callMethod(script, Reflect.field(script, 'set'), [variable, data]);
		#end
	}

	/**
	 * Safely get a variable from the script (thread-safe)
	 */
	public function get(variable:String):Dynamic
	{
		#if (target.threaded)
		mutex.acquire();
		var result:Dynamic = null;
		try
		{
			result = Reflect.callMethod(script, Reflect.field(script, 'get'), [variable]);
		}
		catch (e)
		{
			trace('Error getting variable: ${e.details()}');
		}
		mutex.release();
		return result;
		#else
		return Reflect.callMethod(script, Reflect.field(script, 'get'), [variable]);
		#end
	}

	/**
	 * Call a function in the script (thread-safe)
	 */
	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		#if (target.threaded)
		mutex.acquire();
		var result:Dynamic = null;
		try
		{
			result = Reflect.callMethod(script, Reflect.field(script, 'call'), [func, args]);
		}
		catch (e)
		{
			trace('Error calling function: ${e.details()}');
		}
		mutex.release();
		return result;
		#else
		return Reflect.callMethod(script, Reflect.field(script, 'call'), [func, args]);
		#end
	}

	/**
	 * Execute a function asynchronously using ThreadUtil
	 */
	public function callAsync(func:String, ?args:Array<Dynamic>):Void
	{
		ThreadUtil.execAsync(() ->
		{
			call(func, args);
		});
	}

	/**
	 * Start the script in a separate thread
	 */
	public function start(?updateFunc:Void->Void):Void
	{
		#if (target.threaded)
		if (running)
			return;

		running = true;
		thread = ThreadUtil.createSafe(() ->
		{
			while (running)
			{
				if (!paused && updateFunc != null)
				{
					mutex.acquire();
					try
					{
						updateFunc();
					}
					catch (e)
					{
						trace('Error in script update: ${e.details()}');
					}
					mutex.release();
				}
				Sys.sleep(0.001); // Small delay to prevent CPU hogging
			}
		}, false);
		#else
		if (updateFunc != null)
			updateFunc();
		#end
	}

	/**
	 * Pause script execution
	 */
	public function pause():Void
	{
		#if (target.threaded)
		paused = true;
		#end
	}

	/**
	 * Resume script execution
	 */
	public function resume():Void
	{
		#if (target.threaded)
		paused = false;
		#end
	}

	/**
	 * Stop the script thread
	 */
	public function stop():Void
	{
		#if (target.threaded)
		running = false;
		paused = false;
		#end

		if (Reflect.hasField(script, 'stop'))
		{
			Reflect.callMethod(script, Reflect.field(script, 'stop'), []);
		}
	}
}
