package backend;

#if DISCORD_ALLOWED
import sys.thread.Thread;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "863222024192262205";
	public static var clientID(default, set):String = _defaultID;
	public static var whoIsConnectedTo:Null<cpp.RawConstPointer<DiscordUser>>;
	private static var discordPresence:DiscordRichPresence;

	private static final button1:DiscordButton = new DiscordButton();
	private static final button2:DiscordButton = new DiscordButton();
	public static function initialize():Void
	{
		Sys.println('Initializing Discord RPC...');

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(_defaultID, cpp.RawPointer.addressOf(handlers), false, null);
		button1.label = "Download";
		button1.url = "https://github.com/Paopun20/FNF-PaoPaoEngine/releases";
		button2.label = "GitHub link";
		button2.url = "https://github.com/Paopun20/FNF-PaoPaoEngine";
		
		discordPresence.buttons[0] = button1;
        discordPresence.buttons[1] = button2;

		Thread.create(function():Void
		{
			while (true)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();

				Sys.sleep(2);
			}
		});

		isInitialized = true;
	}

	public dynamic static function shutdown()
	{
		isInitialized = false;
		Sys.println('Shutting down Discord RPC...');
		Discord.Shutdown();
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final username:String = request[0].username;
		final globalName:String = request[0].username;
		final discriminator:Int = Std.parseInt(request[0].discriminator);
		whoIsConnectedTo = request;

		if (discriminator != 0)
			Sys.println('Discord: Connected to user ${username}#${discriminator} ($globalName)');
		else
			Sys.println('Discord: Connected to user @${username} ($globalName)');

		discordPresence = new DiscordRichPresence();
		discordPresence.type = DiscordActivityType_Playing;
		discordPresence.state = "LOADING :3";
		discordPresence.details = "LOADING :3";
		// discordPresence.largeImageKey = "";
		// discordPresence.smallImageKey = "";

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
		changePresence();
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Sys.println('Discord: Disconnected ($errorCode:$message)');
		whoIsConnectedTo = null;
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Sys.println('Discord: Error ($errorCode:$message)');
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon')
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;
        
		discordPresence.state = state;
		discordPresence.details = details;
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.largeImageKey = largeImageKey;
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();
	}

	public static function updatePresence()
	{
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	public static function check()
	{
		if (ClientPrefs.data.discordRPC)
			initialize();
		else if (isInitialized)
			shutdown();
	}

	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function()
		{
			if (isInitialized)
				shutdown();
		});
	}

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if (pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			// trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
#end